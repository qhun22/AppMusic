import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'models/song.dart';
import 'services/audio_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'qhun22Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0C10),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFA855F7),
          surface: Color(0xFF12161F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0C10),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioManager _audioManager = AudioManager();

  // URL gốc của GitHub Pages (người dùng có thể sửa trực tiếp trong cài đặt)
  String _baseUrl = 'https://qhun22.github.io/AppMusic';

  List<Song> _remixSongs = [];
  List<Song> _lofiSongs = [];

  bool _isLoadingRemix = false;
  bool _isLoadingLofi = false;
  String? _remixError;
  String? _lofiError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _audioManager.init();
    _fetchAllSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllSongs() async {
    await Future.wait([
      _fetchSongs('remix'),
      _fetchSongs('lofi'),
    ]);
  }

  Future<void> _fetchSongs(String type) async {
    setState(() {
      if (type == 'remix') {
        _isLoadingRemix = true;
        _remixError = null;
      } else {
        _isLoadingLofi = true;
        _lofiError = null;
      }
    });

    try {
      // Query param chống cache CDN GitHub Pages
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final cleanBaseUrl = _baseUrl.endsWith('/')
          ? _baseUrl.substring(0, _baseUrl.length - 1)
          : _baseUrl;
      final url = Uri.parse('$cleanBaseUrl/$type.json?t=$cacheBuster');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final songs = data.map((json) => Song.fromJson(json)).toList();

        setState(() {
          if (type == 'remix') {
            _remixSongs = songs;
            _isLoadingRemix = false;
          } else {
            _lofiSongs = songs;
            _isLoadingLofi = false;
          }
        });
      } else {
        throw Exception('HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        if (type == 'remix') {
          _remixError = 'Không thể tải danh sách remix ($e)';
          _isLoadingRemix = false;
        } else {
          _lofiError = 'Không thể tải danh sách lofi ($e)';
          _isLoadingLofi = false;
        }
      });
    }
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cấu hình GitHub Pages URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập URL trang GitHub Pages chứa file remix.json & lofi.json:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'https://username.github.io/repo',
                filled: true,
                fillColor: const Color(0xFF0A0C10),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  _baseUrl = newUrl;
                });
                Navigator.pop(ctx);
                _fetchAllSongs();
              }
            },
            child: const Text('Lưu & Tải lại'),
          ),
        ],
      ),
    );
  }

  void _openFullPlayer(Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FullPlayerSheet(song: song, audioManager: _audioManager),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/var.jpg',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, size: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'qhun22Music',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchAllSongs,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cấu hình URL',
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Remix (${_remixSongs.length})'),
            Tab(text: 'Lofi (${_lofiSongs.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongList(
                  songs: _remixSongs,
                  isLoading: _isLoadingRemix,
                  error: _remixError,
                  onRefresh: () => _fetchSongs('remix'),
                ),
                _buildSongList(
                  songs: _lofiSongs,
                  isLoading: _isLoadingLofi,
                  error: _lofiError,
                  onRefresh: () => _fetchSongs('lofi'),
                ),
              ],
            ),
          ),
          // Bottom Mini Player Bar
          _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildSongList({
    required List<Song> songs,
    required bool isLoading,
    required String? error,
    required Future<void> Function() onRefresh,
  }) {
    if (isLoading && songs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (error != null && songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.white38),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _showSettingsDialog,
                child: const Text('Kiểm tra lại Base URL GitHub'),
              ),
            ],
          ),
        ),
      );
    }

    if (songs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.queue_music, size: 50, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có bài hát nào',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final song = songs[index];
          return ValueListenableBuilder<Song?>(
            valueListenable: _audioManager.currentSongNotifier,
            builder: (context, currentSong, _) {
              final isCurrent = currentSong?.id == song.id;
              return Container(
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF1E2538)
                      : const Color(0xFF12161F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFF6366F1).withOpacity(0.5)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF6366F1)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isCurrent
                          ? ValueListenableBuilder<bool>(
                              valueListenable: _audioManager.isPlayingNotifier,
                              builder: (ctx, isPlaying, _) {
                                return Icon(
                                  isPlaying
                                      ? Icons.volume_up
                                      : Icons.pause,
                                  color: Colors.white,
                                  size: 20,
                                );
                              },
                            )
                          : Text(
                              '#${song.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white54,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? const Color(0xFF818CF8)
                          : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    song.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isCurrent ? Icons.equalizer : Icons.play_arrow_rounded,
                      color: isCurrent
                          ? const Color(0xFF6366F1)
                          : Colors.white70,
                    ),
                    onPressed: () {
                      _audioManager.playSong(song, songs);
                    },
                  ),
                  onTap: () {
                    _audioManager.playSong(song, songs);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return ValueListenableBuilder<Song?>(
      valueListenable: _audioManager.currentSongNotifier,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _openFullPlayer(song),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2436), Color(0xFF141926)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator
                StreamBuilder<Duration>(
                  stream: _audioManager.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total =
                        _audioManager.player.duration ?? Duration.zero;
                    final progress = total.inMilliseconds > 0
                        ? (position.inMilliseconds / total.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/var.jpg',
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Đang phát',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF818CF8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _audioManager.isPlayingNotifier,
                        builder: (context, isPlaying, _) {
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                            onPressed: _audioManager.togglePlayPause,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded,
                            size: 26, color: Colors.white70),
                        onPressed: _audioManager.playNext,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Full Player Sheet Modal
class FullPlayerSheet extends StatelessWidget {
  final Song song;
  final AudioManager audioManager;

  const FullPlayerSheet({
    super.key,
    required this.song,
    required this.audioManager,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF10141D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ValueListenableBuilder<Song?>(
        valueListenable: audioManager.currentSongNotifier,
        builder: (context, activeSong, _) {
          final current = activeSong ?? song;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Disc Artwork
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/var.jpg',
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Color(0xFF262F47), Color(0xFF161B27)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.music_note, size: 80, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                current.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ID: #${current.id}',
                style: const TextStyle(fontSize: 13, color: Colors.white38),
              ),
              const SizedBox(height: 20),

              // Stream Progress Slider
              StreamBuilder<Duration>(
                stream: audioManager.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total =
                      audioManager.player.duration ?? Duration.zero;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFF6366F1),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: total.inMilliseconds > 0
                              ? position.inMilliseconds
                                  .clamp(0, total.inMilliseconds)
                                  .toDouble()
                              : 0.0,
                          max: total.inMilliseconds > 0
                              ? total.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            audioManager
                                .seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(total),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: Colors.white,
                    onPressed: audioManager.playPrevious,
                  ),
                  const SizedBox(width: 20),
                  ValueListenableBuilder<bool>(
                    valueListenable: audioManager.isPlayingNotifier,
                    builder: (context, isPlaying, _) {
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                          ),
                        ),
                        child: IconButton(
                          iconSize: 36,
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          color: Colors.white,
                          onPressed: audioManager.togglePlayPause,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: Colors.white,
                    onPressed: audioManager.playNext,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
