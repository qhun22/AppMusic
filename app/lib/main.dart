import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio_background/just_audio_background.dart';
import 'models/song.dart';
import 'services/audio_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo just_audio_background cho iOS Lock Screen & Control Center
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.qhun22.music.channel.audio',
    androidNotificationChannelName: 'qhun22Music Playback',
    androidNotificationOngoing: true,
  );

  // Cấu hình Status Bar sáng màu (Dark Icons) cho nền Trắng & Xanh da trời
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
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
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF0284C7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF0EA5E9),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
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

  // URL gốc của GitHub Pages
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
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final cleanBaseUrl = _baseUrl.endsWith('/')
          ? _baseUrl.substring(0, _baseUrl.length - 1)
          : _baseUrl;
      final url = Uri.parse('$cleanBaseUrl/$type.json?t=$cacheBuster');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final songs = data
            .map((item) => Song.fromJson(
                  item as Map<String, dynamic>,
                  defaultType: type == 'remix' ? 'Remix' : 'Lofi',
                ))
            .toList();

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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Cấu hình nguồn nhạc',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập URL trang GitHub Pages chứa file remix.json & lofi.json:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'https://username.github.io/repo',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
            child: const Text(
              'Lưu & Tải lại',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
        titleSpacing: 16,
        title: Image.asset(
          'assets/QHUN22-min.gif',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'QHUN22',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.5,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF475569)),
            ),
            tooltip: 'Làm mới',
            onPressed: _fetchAllSongs,
          ),
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF475569)),
            ),
            tooltip: 'Cấu hình URL',
            onPressed: _showSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // iOS Native Segmented Tab Control
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: const Color(0xFF0284C7),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Remix (${_remixSongs.length})'),
                Tab(text: 'Lofi (${_lofiSongs.length})'),
              ],
            ),
          ),
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
        child: CircularProgressIndicator(color: Color(0xFF0284C7)),
      );
    }

    if (error != null && songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 32, color: Color(0xFF0284C7)),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _showSettingsDialog,
                child: const Text(
                  'Kiểm tra lại Base URL GitHub',
                  style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (songs.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF0284C7),
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.queue_music_rounded, size: 54, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 14),
                  Text(
                    'Chưa có bài hát nào',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0284C7),
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color: isCurrent ? const Color(0xFFF0F9FF) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFFBAE6FD)
                        : const Color(0xFFE2E8F0).withOpacity(0.6),
                    width: isCurrent ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCurrent
                          ? const Color(0xFF0284C7).withOpacity(0.08)
                          : const Color(0xFF0F172A).withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _audioManager.playSong(song, songs),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Leading Artwork / Playing Badge
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/var.jpg',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: const Color(0xFFE0F2FE),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  width: 44,
                                  height: 44,
                                  color: const Color(0xFF0284C7).withOpacity(0.55),
                                  child: Center(
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _audioManager.isPlayingNotifier,
                                      builder: (ctx, isPlaying, _) {
                                        return Icon(
                                          isPlaying
                                              ? Icons.equalizer_rounded
                                              : Icons.pause_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title and Subtitle Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isCurrent ? FontWeight.w700 : FontWeight.w600,
                                  color: isCurrent
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? const Color(0xFFBAE6FD)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      song.type ?? 'Track',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? const Color(0xFF0369A1)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '#${song.id}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action Button
                        IconButton(
                          icon: Icon(
                            isCurrent
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 34,
                            color: isCurrent
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            if (isCurrent) {
                              _audioManager.togglePlayPause();
                            } else {
                              _audioManager.playSong(song, songs);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
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
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF0284C7).withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Progress indicator bar
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
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0284C7),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/var.jpg',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFE0F2FE),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Color(0xFF0284C7),
                            ),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  song.type != null
                                      ? '${song.type} • Đang phát'
                                      : 'Đang phát',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Play / Pause Circle
                      ValueListenableBuilder<bool>(
                        valueListenable: _audioManager.isPlayingNotifier,
                        builder: (context, isPlaying, _) {
                          return Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0284C7),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                              onPressed: _audioManager.togglePlayPause,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      // Next Track button
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          size: 26,
                          color: Color(0xFF64748B),
                        ),
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
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0284C7),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: ValueListenableBuilder<Song?>(
        valueListenable: audioManager.currentSongNotifier,
        builder: (context, activeSong, _) {
          final current = activeSong ?? song;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // iOS Grab Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header bar: Dismiss icon & Category pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    color: const Color(0xFF64748B),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      (current.type ?? 'qhun22Music').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),

              // Modern Square Album Artwork Card with Soft Sky Shadow
              Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withOpacity(0.20),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/var.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE0F2FE),
                      child: const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 72,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // Title
              Text(
                current.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mã bài hát: #${current.id}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 18),

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
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: const Color(0xFF0284C7),
                          inactiveTrackColor: const Color(0xFFE2E8F0),
                          thumbColor: const Color(0xFF0284C7),
                          overlayColor:
                              const Color(0xFF0284C7).withOpacity(0.12),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDuration(total),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF1F5F9),
                    ),
                    child: IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: const Color(0xFF0F172A),
                      onPressed: audioManager.playPrevious,
                    ),
                  ),
                  const SizedBox(width: 24),
                  ValueListenableBuilder<bool>(
                    valueListenable: audioManager.isPlayingNotifier,
                    builder: (context, isPlaying, _) {
                      return Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 38,
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
                  const SizedBox(width: 24),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF1F5F9),
                    ),
                    child: IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.skip_next_rounded),
                      color: const Color(0xFF0F172A),
                      onPressed: audioManager.playNext,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          );
        },
      ),
    );
  }
}
