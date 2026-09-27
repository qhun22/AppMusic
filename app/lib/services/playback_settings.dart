import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cấu hình hành vi phát nhạc của app iOS - lưu bằng SharedPreferences
class PlaybackSettings {
  static const String _key = 'qhun22.playback.settings.v1';

  // Chế độ phát
  bool autoShuffleOnPlay = false;
  bool smartShuffle = true;
  bool autoplayNext = true;
  bool prevBackToStart = true;

  // Thiết bị & hệ thống
  bool pauseOnUnplug = true;
  bool duckOnNotification = true;

  // Chuyển bài
  bool gapless = true;            // AVQueuePlayer phát liền mạch sẵn có
  double crossfadeSeconds = 0;    // 0 = tắt, 1..12 giây (fade-out rồi chuyển bài)
  double fadeSeconds = 0.2;       // fade in/out khi play/pause

  // Tua
  int seekStep = 10;              // 5 / 10 / 15 / 30 giây

  // Phiên nghe
  bool resumeLastPosition = true;
  bool autoPlayOnResume = false;

  // Hẹn giờ
  bool stopAfterCurrentTrack = false;
  bool fadeLastMinute = true;

  // Tốc độ / cao độ
  double speed = 1.0;
  int pitch = 0;

  Map<String, dynamic> toMap() => {
        'autoShuffleOnPlay': autoShuffleOnPlay,
        'smartShuffle': smartShuffle,
        'autoplayNext': autoplayNext,
        'prevBackToStart': prevBackToStart,
        'pauseOnUnplug': pauseOnUnplug,
        'duckOnNotification': duckOnNotification,
        'gapless': gapless,
        'crossfadeSeconds': crossfadeSeconds,
        'fadeSeconds': fadeSeconds,
        'seekStep': seekStep,
        'resumeLastPosition': resumeLastPosition,
        'autoPlayOnResume': autoPlayOnResume,
        'stopAfterCurrentTrack': stopAfterCurrentTrack,
        'fadeLastMinute': fadeLastMinute,
        'speed': speed,
        'pitch': pitch,
      };

  void applyMap(Map<String, dynamic> map) {
    autoShuffleOnPlay = map['autoShuffleOnPlay'] as bool? ?? autoShuffleOnPlay;
    smartShuffle = map['smartShuffle'] as bool? ?? smartShuffle;
    autoplayNext = map['autoplayNext'] as bool? ?? autoplayNext;
    prevBackToStart = map['prevBackToStart'] as bool? ?? prevBackToStart;
    pauseOnUnplug = map['pauseOnUnplug'] as bool? ?? pauseOnUnplug;
    duckOnNotification = map['duckOnNotification'] as bool? ?? duckOnNotification;
    gapless = map['gapless'] as bool? ?? gapless;
    crossfadeSeconds = (map['crossfadeSeconds'] as num?)?.toDouble() ?? crossfadeSeconds;
    fadeSeconds = (map['fadeSeconds'] as num?)?.toDouble() ?? fadeSeconds;
    seekStep = (map['seekStep'] as num?)?.toInt() ?? seekStep;
    resumeLastPosition = map['resumeLastPosition'] as bool? ?? resumeLastPosition;
    autoPlayOnResume = map['autoPlayOnResume'] as bool? ?? autoPlayOnResume;
    stopAfterCurrentTrack = map['stopAfterCurrentTrack'] as bool? ?? stopAfterCurrentTrack;
    fadeLastMinute = map['fadeLastMinute'] as bool? ?? fadeLastMinute;
    speed = (map['speed'] as num?)?.toDouble() ?? speed;
    pitch = (map['pitch'] as num?)?.toInt() ?? pitch;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw);
      if (decoded is Map) {
        applyMap(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('PlaybackSettings.load lỗi: $e');
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(toMap()));
    } catch (e) {
      debugPrint('PlaybackSettings.save lỗi: $e');
    }
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('PlaybackSettings.reset lỗi: $e');
    }
  }
}
