import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final ValueNotifier<Song?> currentSongNotifier = ValueNotifier<Song?>(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<Song>> currentPlaylistNotifier =
      ValueNotifier<List<Song>>([]);
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(-1);

  ConcatenatingAudioSource? _playlistSource;
  List<int> _currentSongIds = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Cấu hình AudioSession cho iOS Background Playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Cho phép phát lặp toàn bộ playlist
      await _player.setLoopMode(LoopMode.all);

      // Lắng nghe trạng thái phát / tạm dừng
      _player.playerStateStream.listen((state) {
        isPlayingNotifier.value = state.playing;
        if (state.processingState == ProcessingState.completed) {
          playNext();
        }
      });

      // Lắng nghe sự kiện chuyển bài hát (từ Lock Screen, Control Center, Dynamic Island, hoặc tự động)
      _player.currentIndexStream.listen((index) {
        if (index != null &&
            index >= 0 &&
            index < currentPlaylistNotifier.value.length) {
          currentIndexNotifier.value = index;
          currentSongNotifier.value = currentPlaylistNotifier.value[index];
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AudioSession: $e');
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
        album: song.type ?? 'qhun22Music', // Remix hoặc Lofi
        title: song.title,
        artUri: Uri.parse(artUriString), // Link ảnh bìa
      ),
    );
  }

  ConcatenatingAudioSource _buildPlaylistSource(List<Song> playlist) {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: playlist.map((s) => _createAudioSource(s)).toList(),
    );
  }

  Future<void> playSong(Song song, List<Song> playlist) async {
    await init();
    try {
      final safePlaylist = playlist.isNotEmpty ? playlist : [song];
      currentPlaylistNotifier.value = safePlaylist;

      final targetIndex = safePlaylist.indexWhere((s) => s.id == song.id);
      final index = targetIndex >= 0 ? targetIndex : 0;
      currentIndexNotifier.value = index;
      currentSongNotifier.value = safePlaylist[index];

      final newIds = safePlaylist.map((s) => s.id).toList();
      final isSamePlaylist =
          listEquals(_currentSongIds, newIds) && _playlistSource != null;

      if (isSamePlaylist) {
        await _player.seek(Duration.zero, index: index);
      } else {
        _currentSongIds = newIds;
        _playlistSource = _buildPlaylistSource(safePlaylist);
        await _player.setAudioSource(
          _playlistSource!,
          initialIndex: index,
          initialPosition: Duration.zero,
        );
      }

      await _player.play();
    } catch (e) {
      debugPrint('Error playing song (${song.title}): $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> playNext() async {
    final list = currentPlaylistNotifier.value;
    if (list.isEmpty) return;

    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> playPrevious() async {
    final list = currentPlaylistNotifier.value;
    if (list.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero, index: list.length - 1);
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
