import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'playback_settings.dart';

/// Chế độ lặp lại của app
enum RepeatModeApp { off, all, one }

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final PlaybackSettings settings = PlaybackSettings();

  final ValueNotifier<Song?> currentSongNotifier = ValueNotifier<Song?>(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<Song>> currentPlaylistNotifier =
      ValueNotifier<List<Song>>(<Song>[]);
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(-1);
  final ValueNotifier<RepeatModeApp> repeatNotifier =
      ValueNotifier<RepeatModeApp>(RepeatModeApp.off);
  final ValueNotifier<bool> shuffleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> abNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> timerNotifier = ValueNotifier<String>('Tắt');
  final ValueNotifier<String> statusNotifier = ValueNotifier<String>('');

  ConcatenatingAudioSource? _playlistSource;
  List<int> _currentSongIds = <int>[];
  bool _isInitialized = false;
  bool _shuffle = false;
  RepeatModeApp _repeat = RepeatModeApp.off;
  Duration? _abStart;
  Duration? _abEnd;
  Duration? _lastPosition;
  DateTime? _sleepEndsAt;
  bool _stopAfterCurrentTrack = false;
  bool _ducked = false;
  bool _fadingToNext = false;
  double _fadeFactor = 1.0;
  double _volume = 1.0;
  double _duckFactor = 1.0;
  Timer? _fadeTimer;
  Timer? _tickTimer;
  int _lastSavedAtSecond = -1;
  final List<int> _history = <int>[];
  final List<String> _recentArtists = <String>[];

  /// Vị trí nghe dở của phiên trước (dùng để mở app là tiếp tục đúng giây)
  Duration? pendingResumePosition;
  Song? pendingResumeSong;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await settings.load();
      _volume = 1.0;
      await _applyVolume(immediate: true);
      await _applySpeedPitch();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Rút tai nghe / ngắt Bluetooth -> tự tạm dừng
      session.becomingNoisyEventStream.listen((_) {
        if (settings.pauseOnUnplug) {
          statusNotifier.value = 'Đã rút tai nghe – tạm dừng nhạc';
          pause();
        }
      });

      // Cuộc gọi / thông báo -> giảm âm (duck) hoặc tạm dừng, sau đó tự hồi phục
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck &&
              settings.duckOnNotification) {
            _ducked = true;
            _duckFactor = 0.25;
            _applyVolume(immediate: true);
            statusNotifier.value = 'Có thông báo/cuộc gọi – đã giảm âm lượng';
          } else {
            pause();
            statusNotifier.value = 'Tạm dừng do cuộc gọi/thông báo';
          }
        } else {
          _ducked = false;
          _duckFactor = 1.0;
          _applyVolume(immediate: true);
        }
      });

      _player.playerStateStream.listen((state) {
        isPlayingNotifier.value = state.playing;
        if (state.processingState != ProcessingState.completed) return;
        if (_stopAfterCurrentTrack) {
          _stopAfterCurrentTrack = false;
          _sleepEndsAt = null;
          timerNotifier.value = 'Tắt';
          pause();
          statusNotifier.value = 'Hết bài – đã tắt nhạc theo hẹn giờ';
          return;
        }
        if (_repeat == RepeatModeApp.off && !settings.autoplayNext) {
          pause();
          statusNotifier.value = 'Đã phát hết danh sách';
          return;
        }
        playNext();
      });

      _player.currentIndexStream.listen((index) {
        if (index == null ||
            index < 0 ||
            index >= currentPlaylistNotifier.value.length) {
          return;
        }
        currentIndexNotifier.value = index;
        final song = currentPlaylistNotifier.value[index];
        currentSongNotifier.value = song;
        _pushRecent(song);
        _saveSession(force: true);
      });

      _player.positionStream.listen((pos) {
        _lastPosition = pos;
        _checkAbLoop(pos);
        _checkCrossfade(pos);
        if (settings.resumeLastPosition) {
          final sec = pos.inSeconds;
          if (sec - _lastSavedAtSecond >= 5) {
            _lastSavedAtSecond = sec;
            _saveSession();
          }
        }
      });

      _tickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        _tickSleepTimer();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AudioManager: $e');
    }
  }
  AudioSource _createAudioSource(Song song) {
    const fallbackArt = 'https://qhun22.github.io/AppMusic/var.jpg';
    final artUriString = (song.artUrl != null && song.artUrl!.isNotEmpty)
        ? song.artUrl!
        : fallbackArt;

    return AudioSource.uri(
      Uri.parse(song.url),
      tag: MediaItem(
        id: song.id.toString(),
        album: song.type ?? 'qhun22Music',
        title: song.title,
        artist: song.artistGuess,
        artUri: Uri.parse(artUriString),
      ),
    );
  }

  /// Xây thứ tự phát: xáo trộn thông minh (tránh trùng ca sĩ & bài vừa nghe)
  List<Song> buildOrder(
    List<Song> list,
    int startIndex, {
    bool shuffle = false,
    bool smart = true,
  }) {
    if (list.isEmpty) return <Song>[];
    final start = (startIndex >= 0 && startIndex < list.length)
        ? list[startIndex]
        : list.first;
    if (!shuffle) return List<Song>.from(list);

    final rest = <Song>[];
    for (final s in list) {
      if (!identical(s, start)) rest.add(s);
    }
    rest.shuffle(Random());

    if (!smart) return <Song>[start, ...rest];

    // Đẩy các ca sĩ vừa nghe xuống cuối
    rest.sort((a, b) {
      final ra = _recentArtists.contains(a.artistKey) ? 1 : 0;
      final rb = _recentArtists.contains(b.artistKey) ? 1 : 0;
      return ra.compareTo(rb);
    });

    // Tránh 2 bài cùng ca sĩ đứng gần nhau
    final fixed = <Song>[];
    final pending = List<Song>.from(rest);
    var lastKey = start.artistKey;
    while (pending.isNotEmpty) {
      var picked = pending.indexWhere((s) => s.artistKey != lastKey);
      if (picked < 0) picked = 0;
      final song = pending.removeAt(picked);
      fixed.add(song);
      lastKey = song.artistKey;
    }
    return <Song>[start, ...fixed];
  }

  void _pushRecent(Song song) {
    _recentArtists.add(song.artistKey);
    while (_recentArtists.length > 10) {
      _recentArtists.removeAt(0);
    }
  }

  Future<void> _applyLoopMode() async {
    final mode = _repeat == RepeatModeApp.one
        ? LoopMode.one
        : (_repeat == RepeatModeApp.all ? LoopMode.all : LoopMode.off);
    try {
      await _player.setLoopMode(mode);
    } catch (e) {
      debugPrint('setLoopMode lỗi: $e');
    }
  }

  Future<void> _applyVolume({bool immediate = false}) async {
    final value = (_volume * _fadeFactor * _duckFactor).clamp(0.0, 1.0).toDouble();
    try {
      await _player.setVolume(value);
    } catch (e) {
      debugPrint('setVolume lỗi: $e');
    }
  }

  /// Fade âm lượng mượt (dùng cho Play/Pause, crossfade, hẹn giờ)
  Future<void> _fadeVolumeTo(double target, double seconds) async {
    _fadeTimer?.cancel();
    if (seconds <= 0.02) {
      _fadeFactor = target;
      await _applyVolume(immediate: true);
      return;
    }
    const steps = 12;
    final stepMs = ((seconds * 1000) / steps).round().clamp(10, 2000).toInt();
    final start = _fadeFactor;
    var i = 0;
    final completer = Completer<void>();
    _fadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      i++;
      _fadeFactor = start + (target - start) * (i / steps);
      _applyVolume(immediate: true);
      if (i >= steps) {
        timer.cancel();
        _fadeFactor = target;
        _applyVolume(immediate: true);
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    await _applyVolume(immediate: true);
    await settings.save();
  }

  double get volume => _volume;
  bool get isDucked => _ducked;
  RepeatModeApp get repeatMode => _repeat;
  bool get isShuffleOn => _shuffle;
  Future<void> _loadPlaylist(
    List<Song> ordered, {
    int startIndex = 0,
    bool autoplay = true,
    Duration position = Duration.zero,
  }) async {
    try {
      if (ordered.isEmpty) return;
      currentPlaylistNotifier.value = ordered;
      _currentSongIds = ordered.map((s) => s.id).toList();
      _history.clear();
      _playlistSource = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: ordered.map(_createAudioSource).toList(),
      );
      await _player.setAudioSource(
        _playlistSource!,
        initialIndex: startIndex,
        initialPosition: position,
      );
      await _applyLoopMode();
      await _applySpeedPitch();
      await _applyVolume(immediate: true);
      currentIndexNotifier.value = startIndex;
      currentSongNotifier.value = ordered[startIndex];
      _pushRecent(ordered[startIndex]);
      if (autoplay) {
        await _fadeVolumeTo(1.0, settings.fadeSeconds);
        await _player.play();
      }
      _saveSession(force: true);
    } catch (e) {
      debugPrint('Error loading playlist: $e');
      statusNotifier.value = 'Không phát được bài (kiểm tra mạng): $e';
    }
  }

  /// Phát 1 bài trong danh sách (giữ nguyên API cũ để main.dart dùng lại)
  Future<void> playSong(Song song, List<Song> playlist) async {
    await init();
    final safeList = playlist.isNotEmpty ? playlist : <Song>[song];
    var index = safeList.indexWhere((s) => s.id == song.id);
    if (index < 0) index = 0;
    final wantShuffle = _shuffle || settings.autoShuffleOnPlay;
    final ordered = buildOrder(
      safeList,
      index,
      shuffle: wantShuffle,
      smart: settings.smartShuffle,
    );
    _shuffle = wantShuffle;
    shuffleNotifier.value = _shuffle;
    await _loadPlaylist(ordered, startIndex: 0, autoplay: true);
  }

  /// Phát cả danh sách từ vị trí bất kỳ
  Future<void> playPlaylist(
    List<Song> list, {
    int startIndex = 0,
    bool? shuffle,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async {
    await init();
    final wantShuffle = shuffle ?? _shuffle;
    final ordered = buildOrder(
      list,
      startIndex,
      shuffle: wantShuffle,
      smart: settings.smartShuffle,
    );
    _shuffle = wantShuffle;
    shuffleNotifier.value = _shuffle;
    await _loadPlaylist(
      ordered,
      startIndex: 0,
      autoplay: autoplay,
      position: position,
    );
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Tạm dừng: nhỏ dần âm lượng rồi mới tắt hẳn (tránh tiếng "bụp")
  Future<void> pause({bool fade = true}) async {
    final seconds = fade ? settings.fadeSeconds : 0.0;
    if (seconds <= 0.05) {
      try {
        await _player.pause();
      } catch (e) {
        debugPrint('pause lỗi: $e');
      }
      return;
    }
    await _fadeVolumeTo(0.0, seconds);
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('pause lỗi: $e');
    }
    _fadeFactor = 1.0;
    await _applyVolume(immediate: true);
  }

  /// Phát: âm lượng tăng dần để không giật mình
  Future<void> resume() async {
    await init();
    if (_player.playing) return;
    if (currentPlaylistNotifier.value.isEmpty) {
      statusNotifier.value = 'Chưa có bài hát nào trong danh sách';
      return;
    }
    final seconds = settings.fadeSeconds;
    _fadeFactor = 0.0;
    await _applyVolume(immediate: true);
    try {
      await _player.play();
    } catch (e) {
      debugPrint('play lỗi: $e');
      statusNotifier.value = 'Không phát được nhạc: $e';
      _fadeFactor = 1.0;
      await _applyVolume(immediate: true);
      return;
    }
    if (seconds > 0.05) {
      await _fadeVolumeTo(1.0, seconds);
    } else {
      _fadeFactor = 1.0;
      await _applyVolume(immediate: true);
    }
  }
  Future<void> playNext() async {
    final list = currentPlaylistNotifier.value;
    if (list.isEmpty) return;
    try {
      if (_player.hasNext) {
        await _player.seekToNext();
      } else if (_repeat == RepeatModeApp.all || settings.autoplayNext) {
        await _player.seek(Duration.zero, index: 0);
      } else {
        await pause();
        statusNotifier.value = 'Đã phát hết danh sách';
      }
    } catch (e) {
      debugPrint('playNext lỗi: $e');
    }
  }

  Future<void> playPrevious() async {
    final list = currentPlaylistNotifier.value;
    if (list.isEmpty) return;
    try {
      if (settings.prevBackToStart && _player.position.inSeconds > 3) {
        await _player.seek(Duration.zero);
        statusNotifier.value = 'Đã tua về đầu bài hiện tại';
        return;
      }
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else {
        await _player.seek(Duration.zero, index: list.length - 1);
      }
    } catch (e) {
      debugPrint('playPrevious lỗi: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('seek lỗi: $e');
    }
  }

  /// Tua nhanh/lùi theo số giây (nút bấm, chạm 2 lần, tai nghe)
  Future<void> skipSeconds(int seconds) async {
    final total = _player.duration;
    var target = _player.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (total != null && target > total) target = total;
    await seek(target);
    statusNotifier.value =
        seconds > 0 ? 'Tua tới ${seconds}s' : 'Tua lùi ${-seconds}s';
  }

  Future<void> setRepeat(RepeatModeApp mode) async {
    _repeat = mode;
    repeatNotifier.value = mode;
    await _applyLoopMode();
  }

  Future<RepeatModeApp> cycleRepeat() async {
    final next = _repeat == RepeatModeApp.off
        ? RepeatModeApp.all
        : (_repeat == RepeatModeApp.all ? RepeatModeApp.one : RepeatModeApp.off);
    await setRepeat(next);
    return next;
  }

  String get repeatLabel {
    switch (_repeat) {
      case RepeatModeApp.all:
        return 'Lặp toàn bộ';
      case RepeatModeApp.one:
        return 'Lặp 1 bài';
      case RepeatModeApp.off:
      default:
        return 'Tắt';
    }
  }

  /// Bật/tắt xáo trộn: đổi thứ tự hàng đợi nhưng giữ nguyên bài đang phát
  Future<void> setShuffle(bool value) async {
    _shuffle = value;
    shuffleNotifier.value = value;
    if (!value) return;
    final list = currentPlaylistNotifier.value;
    if (list.isEmpty) return;
    final current = currentSongNotifier.value;
    var index = current == null ? 0 : list.indexWhere((s) => s.id == current.id);
    if (index < 0) index = 0;
    final ordered = buildOrder(
      list,
      index,
      shuffle: true,
      smart: settings.smartShuffle,
    );
    final position = _player.position;
    final wasPlaying = _player.playing;
    await _loadPlaylist(
      ordered,
      startIndex: 0,
      autoplay: wasPlaying,
      position: position,
    );
  }

  /// Bấm A-B: lần 1 đặt điểm A, lần 2 đặt điểm B, lần 3 tắt
  Future<String> cycleAbRepeat() async {
    final pos = _player.position;
    if (_abStart == null) {
      _abStart = pos;
      _abEnd = null;
      abNotifier.value = 'A = ${fmtClock(pos)} · bấm A-B để đặt điểm B';
    } else if (_abEnd == null) {
      if (pos - _abStart! < const Duration(seconds: 1)) {
        abNotifier.value = 'Điểm B phải sau điểm A ít nhất 1 giây';
        return abNotifier.value;
      }
      _abEnd = pos;
      abNotifier.value =
          'Đang lặp ${fmtClock(_abStart!)} → ${fmtClock(_abEnd!)} · bấm A-B để tắt';
    } else {
      _abStart = null;
      _abEnd = null;
      abNotifier.value = '';
      return 'Đã tắt lặp đoạn A-B';
    }
    return abNotifier.value;
  }

  void clearAbRepeat() {
    _abStart = null;
    _abEnd = null;
    abNotifier.value = '';
  }

  bool get hasAbRepeat => _abStart != null && _abEnd != null;

  void _checkAbLoop(Duration pos) {
    final a = _abStart;
    final b = _abEnd;
    if (a == null || b == null) return;
    if (pos >= b) {
      seek(a);
    }
  }

  static String fmtClock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
  Future<void> setSpeed(double value) async {
    settings.speed = value.clamp(0.5, 2.0).toDouble();
    await _applySpeedPitch();
    await settings.save();
  }

  Future<void> setPitch(int semitones) async {
    settings.pitch = semitones.clamp(-12, 12).toInt();
    await _applySpeedPitch();
    await settings.save();
  }

  Future<void> _applySpeedPitch() async {
    try {
      await _player.setSpeed(settings.speed.clamp(0.5, 2.0).toDouble());
    } catch (e) {
      debugPrint('setSpeed lỗi: $e');
    }
    // Đổi cao độ: chỉ một số nền tảng hỗ trợ (dùng dynamic + try/catch cho an toàn)
    final pitchFactor = pow(2, settings.pitch / 12).toDouble();
    try {
      final dynamic p = _player;
      await p.setPitch(pitchFactor);
    } catch (e) {
      debugPrint('setPitch không được hỗ trợ trên nền tảng này: $e');
    }
  }

  bool get pitchSupported {
    try {
      final dynamic p = _player;
      final dynamic probe = p.pitch;
      return probe != null || true;
    } catch (_) {
      return false;
    }
  }

  /// Sleep timer: 15/30/45/60 phút hoặc tuỳ chỉnh, có thể chờ hết bài hiện tại
  void startSleepTimer(int minutes) {
    _stopAfterCurrentTrack = settings.stopAfterCurrentTrack;
    if (_stopAfterCurrentTrack) {
      _sleepEndsAt = null;
      timerNotifier.value = 'Hết bài hiện tại';
      statusNotifier.value = 'Sẽ tắt nhạc sau khi hết bài hiện tại';
    } else {
      _sleepEndsAt = DateTime.now().add(Duration(minutes: minutes));
      timerNotifier.value = '$minutes phút';
      statusNotifier.value = 'Đã hẹn giờ tắt nhạc sau $minutes phút';
    }
  }

  void cancelSleepTimer() {
    _sleepEndsAt = null;
    _stopAfterCurrentTrack = false;
    _fadeFactor = 1.0;
    _applyVolume(immediate: true);
    timerNotifier.value = 'Tắt';
    statusNotifier.value = 'Đã huỷ hẹn giờ tắt nhạc';
  }

  bool get hasSleepTimer => _sleepEndsAt != null || _stopAfterCurrentTrack;

  void _tickSleepTimer() {
    final ends = _sleepEndsAt;
    if (ends == null) return;
    final left = ends.difference(DateTime.now());
    if (left.inMilliseconds <= 0) {
      _sleepEndsAt = null;
      timerNotifier.value = 'Tắt';
      pause();
      _fadeFactor = 1.0;
      _applyVolume(immediate: true);
      statusNotifier.value = 'Đã tắt nhạc theo hẹn giờ';
      return;
    }
    if (settings.fadeLastMinute &&
        left.inSeconds <= 60 &&
        _player.playing &&
        settings.fadeSeconds < 1) {
      _fadeFactor = (left.inSeconds / 60).clamp(0.05, 1.0).toDouble();
      _applyVolume(immediate: true);
    }
    timerNotifier.value =
        '${left.inMinutes} phút ${left.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
  }

  /// "Crossfade" trên iOS: nhỏ dần bài hiện tại rồi chuyển bài rồi to dần trở lại.
  /// (AVQueuePlayer không phát chồng 2 bài nên không thể giao thoa thật như web.)
  void _checkCrossfade(Duration pos) {
    final cf = settings.crossfadeSeconds;
    if (cf <= 0 || _fadingToNext) return;
    final total = _player.duration;
    if (total == null || total.inMilliseconds <= 0) return;
    final remainingMs = (total - pos).inMilliseconds;
    final cfMs = (cf * 1000).round();
    if (remainingMs <= cfMs && remainingMs > 300) {
      _fadingToNext = true;
      _runFadeTransition(cf);
    }
  }

  Future<void> _runFadeTransition(double seconds) async {
    try {
      await _fadeVolumeTo(0.0, seconds);
      if (_player.hasNext) {
        await _player.seekToNext();
      }
      await _fadeVolumeTo(1.0, settings.fadeSeconds > 0.05 ? settings.fadeSeconds : 0.3);
      statusNotifier.value = 'Chuyển bài mượt (fade ${seconds.toStringAsFixed(1)}s)';
    } catch (e) {
      debugPrint('fade transition lỗi: $e');
      _fadeFactor = 1.0;
      await _applyVolume(immediate: true);
    } finally {
      _fadingToNext = false;
    }
  }
  List<Song> get queue => currentPlaylistNotifier.value;

  Future<void> enqueueLast(Song song) async {
    final list = List<Song>.from(currentPlaylistNotifier.value)..add(song);
    await _reloadKeepingCurrent(list);
    statusNotifier.value = 'Đã thêm vào cuối hàng đợi: ${song.title}';
  }

  Future<void> enqueueNext(Song song) async {
    final list = List<Song>.from(currentPlaylistNotifier.value);
    final idx = currentIndexNotifier.value;
    final insertAt = (idx >= 0 && idx < list.length) ? idx + 1 : list.length;
    list.insert(insertAt, song);
    await _reloadKeepingCurrent(list);
    statusNotifier.value = 'Sẽ phát tiếp theo: ${song.title}';
  }

  Future<void> removeFromQueue(int index) async {
    final list = List<Song>.from(currentPlaylistNotifier.value);
    if (index < 0 || index >= list.length) return;
    final wasCurrent = index == currentIndexNotifier.value;
    list.removeAt(index);
    await _reloadKeepingCurrent(list, fallbackIndex: wasCurrent ? index : null);
    statusNotifier.value = 'Đã xoá 1 bài khỏi hàng đợi';
  }

  /// Kéo-thả đổi thứ tự (chỉ số kiểu ReorderableListView)
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final list = List<Song>.from(currentPlaylistNotifier.value);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target >= list.length) target = list.length - 1;
    final item = list.removeAt(oldIndex);
    list.insert(target, item);
    await _reloadKeepingCurrent(list);
  }

  Future<void> clearQueue() async {
    await pause(fade: false);
    currentPlaylistNotifier.value = <Song>[];
    currentSongNotifier.value = null;
    currentIndexNotifier.value = -1;
    _history.clear();
    _playlistSource = null;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('stop lỗi: $e');
    }
    _saveSession(force: true);
    statusNotifier.value = 'Đã xoá sạch hàng đợi';
  }

  /// Đổi danh sách phát nhưng giữ nguyên bài + vị trí đang nghe
  Future<void> _reloadKeepingCurrent(List<Song> list, {int? fallbackIndex}) async {
    if (list.isEmpty) {
      await clearQueue();
      return;
    }
    final current = currentSongNotifier.value;
    var index = current == null ? 0 : list.indexWhere((s) => s.id == current.id);
    if (index < 0) {
      final fb = fallbackIndex ?? 0;
      index = fb.clamp(0, list.length - 1).toInt();
    }
    final position = _player.position;
    final wasPlaying = _player.playing;
    await _loadPlaylist(
      list,
      startIndex: index,
      autoplay: wasPlaying,
      position: position,
    );
  }

  /// JSON hàng đợi để "Lưu thành Playlist" (copy vào clipboard / chia sẻ)
  String queueAsJson() {
    final data = currentPlaylistNotifier.value
        .map((s) => <String, dynamic>{'id': s.id, 'title': s.title, 'url': s.url})
        .toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  /* ---------------- Ghi nhớ phiên nghe ---------------- */
  static const String _sessionKey = 'qhun22.session.v1';

  Future<void> saveSessionNow() => _saveSession(force: true);

  Future<void> _saveSession({bool force = false}) async {
    if (!settings.resumeLastPosition) return;
    final song = currentSongNotifier.value;
    if (song == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'songId': song.id,
        'positionMs': _player.position.inMilliseconds,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'queue': currentPlaylistNotifier.value
            .map((s) => <String, dynamic>{
                  'id': s.id,
                  'title': s.title,
                  'url': s.url,
                  'type': s.type,
                })
            .toList(),
      };
      await prefs.setString(_sessionKey, json.encode(payload));
    } catch (e) {
      debugPrint('saveSession lỗi: $e');
    }
  }

  Future<Map<String, dynamic>?> loadSession() async {
    if (!settings.resumeLastPosition) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = json.decode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (e) {
      debugPrint('loadSession lỗi: $e');
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e) {
      debugPrint('clearSession lỗi: $e');
    }
  }

  /// Mở app: khôi phục đúng hàng đợi + giây đang nghe dở của lần trước
  Future<bool> restoreSession() async {
    final data = await loadSession();
    if (data == null) return false;
    final rawQueue = data['queue'];
    final list = <Song>[];
    if (rawQueue is List) {
      for (final item in rawQueue) {
        if (item is Map) {
          final song = Song.fromJson(Map<String, dynamic>.from(item));
          if (song.url.isNotEmpty) list.add(song);
        }
      }
    }
    if (list.isEmpty) return false;
    final savedId = (data['songId'] as num?)?.toInt();
    var index = savedId == null ? 0 : list.indexWhere((s) => s.id == savedId);
    if (index < 0) index = 0;
    final positionMs = (data['positionMs'] as num?)?.toInt() ?? 0;
    final position = Duration(milliseconds: positionMs);
    pendingResumeSong = list[index];
    pendingResumePosition = position;
    final ordered = buildOrder(
      list,
      index,
      shuffle: _shuffle,
      smart: settings.smartShuffle,
    );
    await _loadPlaylist(
      ordered,
      startIndex: 0,
      autoplay: settings.autoPlayOnResume,
      position: position,
    );
    statusNotifier.value = settings.autoPlayOnResume
        ? 'Tiếp tục phát từ vị trí đã nghe dở'
        : 'Sẵn sàng tiếp tục: ${list[index].title} (${fmtClock(position)}) – bấm Play';
    return true;
  }

  void dispose() {
    _fadeTimer?.cancel();
    _tickTimer?.cancel();
    _player.dispose();
  }
}






