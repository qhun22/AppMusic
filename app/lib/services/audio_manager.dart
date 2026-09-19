import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
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

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Cấu hình AudioSession cho iOS Background Playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      _player.playerStateStream.listen((state) {
        isPlayingNotifier.value = state.playing;
        if (state.processingState == ProcessingState.completed) {
          playNext();
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AudioSession: $e');
    }
  }

  Future<void> playSong(Song song, List<Song> playlist) async {
    await init();
    try {
      currentPlaylistNotifier.value = playlist;
      final index = playlist.indexWhere((s) => s.id == song.id);
      currentIndexNotifier.value = index >= 0 ? index : 0;
      currentSongNotifier.value = song;

      await _player.setUrl(song.url);
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

    int nextIndex = currentIndexNotifier.value + 1;
    if (nextIndex >= list.length) {
      nextIndex = 0; // Vòng lặp lại từ đầu danh sách
    }

    final nextSong = list[nextIndex];
    await playSong(nextSong, list);
  }

  Future<void> playPrevious() async {
    final list = currentPlaylistNotifier.value;
    if (list.isEmpty) return;

    int prevIndex = currentIndexNotifier.value - 1;
    if (prevIndex < 0) {
      prevIndex = list.length - 1;
    }

    final prevSong = list[prevIndex];
    await playSong(prevSong, list);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
