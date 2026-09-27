import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../services/audio_manager.dart';

/// Bảng màu dùng chung cho app (trắng – xanh dương basic)
const Color kBlue = Color(0xFF0284C7);
const Color kBlueDark = Color(0xFF0369A1);
const Color kBlueSoft = Color(0xFFF0F9FF);
const Color kBlueBorder = Color(0xFFBAE6FD);
const Color kLine = Color(0xFFE2E8F0);
const Color kTextDark = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);

/// Khung chung cho các bottom sheet (nền trắng, bo góc trên, có tiêu đề)
class SheetShell extends StatelessWidget {
  const SheetShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.heightFactor = 0.78,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final double heightFactor;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: mediaQuery.size.height * heightFactor,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: kMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Wrap(spacing: 8, runSpacing: 8, children: actions),
            ),
          const Divider(height: 1, color: kLine),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Nút chip nhỏ dùng trong các sheet
class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

/// Hàng công tắc (switch) nền trắng, có mô tả phụ
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 11.5, color: kMuted),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: kBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Slider có nhãn + giá trị
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueText,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? valueText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
              ),
              Text(
                valueText ?? value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: kBlueDark,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: kBlue,
              inactiveTrackColor: kLine,
              thumbColor: kBlue,
              overlayColor: kBlue.withOpacity(0.12),
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiêu đề nhóm trong sheet
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: kBlueDark,
        ),
      ),
    );
  }
}

/// Thông báo trống
Widget emptyHint(String text) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: kMuted, height: 1.5),
      ),
    ),
  );
}

/* ================= SHEET: HÀNG ĐỢI ================= */
Future<void> showQueueSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return ValueListenableBuilder<List<Song>>(
        valueListenable: am.currentPlaylistNotifier,
        builder: (context, list, _) {
          final currentIndex = am.currentIndexNotifier.value;
          return SheetShell(
            title: 'Hàng đợi',
            subtitle:
                '${list.length} bài · đang phát: ${am.currentSongNotifier.value?.shortTitle ?? "—"}',
            heightFactor: 0.85,
            actions: [
              ChipButton(
                label: 'Copy playlist JSON',
                icon: Icons.copy_rounded,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: am.queueAsJson()));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Đã copy playlist JSON vào clipboard')),
                    );
                  }
                },
              ),
              ChipButton(
                label: 'Xoá sạch',
                icon: Icons.delete_sweep_rounded,
                onTap: () async {
                  await am.clearQueue();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
            child: list.isEmpty
                ? emptyHint('Hàng đợi đang trống.\nHãy chọn bài trong tab Thư viện.')
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: list.length,
                    onReorder: (oldIndex, newIndex) {
                      am.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = list[index];
                      final isCurrent = index == currentIndex;
                      return Container(
                        key: ValueKey<String>('q_${song.id}_$index'),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrent ? kBlueSoft : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? kBlue : kLine,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            isCurrent
                                ? Icons.equalizer_rounded
                                : Icons.drag_handle_rounded,
                            color: isCurrent ? kBlue : kMuted,
                            size: 20,
                          ),
                          title: Text(
                            song.shortTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isCurrent ? FontWeight.w700 : FontWeight.w600,
                              color: kTextDark,
                            ),
                          ),
                          subtitle: Text(
                            '${song.type ?? "Track"} · #${song.id}',
                            style: const TextStyle(fontSize: 11, color: kMuted),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: kMuted,
                            onPressed: () => am.removeFromQueue(index),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await am.playPlaylist(list, startIndex: index);
                          },
                        ),
                      );
                    },
                  ),
          );
        },
      );
    },
  );
}
/* ================= SHEET: HẸN GIỜ TẮT NHẠC ================= */
Future<void> showSleepTimerSheet(BuildContext context, AudioManager am) {
  var minutes = 30.0;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SheetShell(
            title: 'Hẹn giờ tắt nhạc',
            subtitle: 'Sleep timer · tự nhỏ dần âm lượng rồi tắt',
            heightFactor: 0.72,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Chọn nhanh'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in <int>[15, 30, 45, 60])
                          ChipButton(
                            label: '$m phút',
                            icon: Icons.timer_outlined,
                            onTap: () {
                              am.startSleepTimer(m);
                              Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                  ),
                  LabeledSlider(
                    label: 'Tuỳ chỉnh',
                    value: minutes,
                    min: 1,
                    max: 180,
                    divisions: 179,
                    valueText: '${minutes.round()} phút',
                    onChanged: (v) => setSheetState(() => minutes = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              am.startSleepTimer(minutes.round());
                              Navigator.pop(ctx);
                            },
                            child: const Text('Bắt đầu hẹn giờ'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kBlueDark,
                            padding: const EdgeInsets.symmetric(
                                vertical: 13, horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            am.cancelSleepTimer();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Huỷ'),
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle('Tuỳ chọn'),
                  SwitchRow(
                    title: 'Phát hết bài hiện tại rồi mới tắt',
                    subtitle: 'Bài hát không bị dừng đột ngột giữa chừng',
                    value: s.stopAfterCurrentTrack,
                    onChanged: (v) {
                      setSheetState(() => s.stopAfterCurrentTrack = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Tự nhỏ dần âm lượng trong 1 phút cuối',
                    value: s.fadeLastMinute,
                    onChanged: (v) {
                      setSheetState(() => s.fadeLastMinute = v);
                      s.save();
                    },
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: am.timerNotifier,
                    builder: (context, value, _) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        child: Text(
                          value == 'Tắt'
                              ? 'Chưa hẹn giờ.'
                              : 'Đang hẹn giờ: $value',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kBlueDark,
                          ),
                        ),
                      );
                    },
                  ),
                  noteBox(
                    'Mẹo: bật "Phát hết bài hiện tại rồi mới tắt" khi nghe album/nhạc live để không bị cắt giữa bài.',
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
/* ================= SHEET: TỐC ĐỘ & CAO ĐỘ ================= */
Future<void> showSpeedPitchSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SheetShell(
            title: 'Tốc độ & Cao độ',
            subtitle: 'Nghe nhanh/chậm mà vẫn rõ lời, đổi tông khi tập hát',
            heightFactor: 0.66,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Tốc độ phát (giữ nguyên giọng)'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sp in <double>[0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                          ChipButton(
                            label: '${sp}x',
                            active: (s.speed - sp).abs() < 0.001,
                            onTap: () {
                              am.setSpeed(sp);
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  LabeledSlider(
                    label: 'Tuỳ chỉnh tốc độ',
                    value: s.speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30,
                    valueText: '${s.speed.toStringAsFixed(2)}x',
                    onChanged: (v) {
                      am.setSpeed(v);
                      setSheetState(() {});
                    },
                  ),
                  const SectionTitle('Cao độ / Tông giọng (nửa cung)'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in <int>[-6, -3, -1, 0, 1, 3, 6])
                          ChipButton(
                            label: p > 0 ? '+$p' : '$p',
                            active: s.pitch == p,
                            onTap: () {
                              am.setPitch(p);
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  LabeledSlider(
                    label: 'Tuỳ chỉnh cao độ',
                    value: s.pitch.toDouble(),
                    min: -12,
                    max: 12,
                    divisions: 24,
                    valueText: '${s.pitch}',
                    onChanged: (v) {
                      am.setPitch(v.round());
                      setSheetState(() {});
                    },
                  ),
                  noteBox(
                    'Tốc độ xử lý ở tầng hệ điều hành nên giọng hát không bị biến dạng. '
                    'Cao độ (pitch) không phải máy iOS nào cũng hỗ trợ — nếu không đổi được tông, '
                    'hãy dùng Tốc độ, hoặc chờ bản DSP native.',
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
/* ================= SHEET: ÂM THANH & DSP ================= */
Future<void> showDspSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SheetShell(
            title: 'Âm thanh & DSP',
            subtitle: 'Gapless, crossfade, fade, ducking, rút tai nghe',
            heightFactor: 0.74,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Chuyển bài mượt mà'),
                  SwitchRow(
                    title: 'Phát liền mạch (Gapless)',
                    subtitle: 'iOS dùng AVQueuePlayer nên gần như không có khoảng lặng',
                    value: s.gapless,
                    onChanged: (v) {
                      setSheetState(() => s.gapless = v);
                      s.save();
                    },
                  ),
                  LabeledSlider(
                    label: 'Chuyển bài mượt (fade-out → bài mới)',
                    value: s.crossfadeSeconds,
                    min: 0,
                    max: 12,
                    divisions: 12,
                    valueText: s.crossfadeSeconds == 0
                        ? 'Tắt'
                        : '${s.crossfadeSeconds.round()}s',
                    onChanged: (v) {
                      setSheetState(() => s.crossfadeSeconds = v);
                      s.save();
                    },
                  ),
                  LabeledSlider(
                    label: 'Fade in/out khi Play/Pause',
                    value: s.fadeSeconds,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    valueText: '${s.fadeSeconds.toStringAsFixed(2)}s',
                    onChanged: (v) {
                      setSheetState(() => s.fadeSeconds = v);
                      s.save();
                    },
                  ),
                  const SectionTitle('Tương tác hệ thống'),
                  SwitchRow(
                    title: 'Tạm dừng khi rút tai nghe',
                    subtitle: 'Ngắt Bluetooth/rút jack thì không phát to ra loa ngoài',
                    value: s.pauseOnUnplug,
                    onChanged: (v) {
                      setSheetState(() => s.pauseOnUnplug = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Giảm âm khi có thông báo (Audio Ducking)',
                    subtitle: 'Có cuộc gọi/thông báo thì tự nhỏ lại rồi to lại',
                    value: s.duckOnNotification,
                    onChanged: (v) {
                      setSheetState(() => s.duckOnNotification = v);
                      s.save();
                    },
                  ),
                  const SectionTitle('Âm lượng'),
                  LabeledSlider(
                    label: 'Âm lượng hiện tại',
                    value: am.volume,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    valueText: '${(am.volume * 100).round()}%',
                    onChanged: (v) {
                      am.setVolume(v);
                      setSheetState(() {});
                    },
                  ),
                  noteBox(
                    'EQ nhiều dải, âm thanh vòm và pitch shift chất lượng cao cần Audio Unit native '
                    '(AVAudioEngine) nên chưa có trên bản iOS này. Bản web (index.html) đã có '
                    'EQ 10 dải + preset + Bass/Treble + cân bằng L/R + Mono.',
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
/* ================= SHEET: CÀI ĐẶT HÀNH VI PHÁT ================= */
Future<void> showPlaybackSettingsSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SheetShell(
            title: 'Cài đặt phát nhạc',
            subtitle: 'Chế độ phát, cử chỉ tua, ghi nhớ phiên nghe',
            heightFactor: 0.86,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Chế độ phát'),
                  SwitchRow(
                    title: 'Tự xáo trộn khi mở app / chọn playlist',
                    value: s.autoShuffleOnPlay,
                    onChanged: (v) {
                      setSheetState(() => s.autoShuffleOnPlay = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Xáo trộn thông minh',
                    subtitle: 'Không lặp bài vừa nghe, tránh 2 bài cùng ca sĩ gần nhau',
                    value: s.smartShuffle,
                    onChanged: (v) {
                      setSheetState(() => s.smartShuffle = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Tự động phát liên tục (Autoplay Next)',
                    subtitle: 'Hết danh sách vẫn phát tiếp thay vì im lặng',
                    value: s.autoplayNext,
                    onChanged: (v) {
                      setSheetState(() => s.autoplayNext = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Previous khi đã phát > 3 giây thì về đầu bài',
                    value: s.prevBackToStart,
                    onChanged: (v) {
                      setSheetState(() => s.prevBackToStart = v);
                      s.save();
                    },
                  ),
                  const SectionTitle('Bước tua ± (giây)'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final step in <int>[5, 10, 15, 30])
                          ChipButton(
                            label: '$step giây',
                            active: s.seekStep == step,
                            onTap: () {
                              setSheetState(() => s.seekStep = step);
                              s.save();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SectionTitle('Ghi nhớ phiên nghe'),
                  SwitchRow(
                    title: 'Tự phát lại đúng vị trí cũ khi mở app',
                    value: s.resumeLastPosition,
                    onChanged: (v) {
                      setSheetState(() => s.resumeLastPosition = v);
                      s.save();
                      if (!v) am.clearSession();
                    },
                  ),
                  SwitchRow(
                    title: 'Mở app là phát tiếp luôn',
                    value: s.autoPlayOnResume,
                    onChanged: (v) {
                      setSheetState(() => s.autoPlayOnResume = v);
                      s.save();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Xoá dữ liệu đã lưu (cài đặt + phiên nghe)'),
                      onPressed: () async {
                        await s.reset();
                        await am.clearSession();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
/* ================= SHEET: ĐIỀU KHIỂN NHANH (mở từ AppBar) ================= */
Future<void> showQuickControlsSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final song = am.currentSongNotifier.value;
          return SheetShell(
            title: 'Điều khiển nhanh',
            subtitle: song == null
                ? 'Chưa có bài hát nào đang phát'
                : 'Đang phát: ${song.shortTitle}',
            heightFactor: 0.72,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Chế độ phát'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChipButton(
                          label: 'Xáo trộn',
                          icon: Icons.shuffle_rounded,
                          active: am.isShuffleOn,
                          onTap: () async {
                            await am.setShuffle(!am.isShuffleOn);
                            setSheetState(() {});
                          },
                        ),
                        ChipButton(
                          label: 'Lặp: ${am.repeatLabel}',
                          icon: Icons.repeat_rounded,
                          active: am.repeatMode != RepeatModeApp.off,
                          onTap: () async {
                            await am.cycleRepeat();
                            setSheetState(() {});
                          },
                        ),
                        ChipButton(
                          label: 'Lặp đoạn A-B',
                          icon: Icons.repeat_on_rounded,
                          active: am.hasAbRepeat,
                          onTap: () async {
                            await am.cycleAbRepeat();
                            setSheetState(() {});
                          },
                        ),
                        ChipButton(
                          label: 'Tua ±${am.settings.seekStep}s',
                          icon: Icons.fast_forward_rounded,
                          onTap: () async {
                            await am.skipSeconds(am.settings.seekStep);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (am.abNotifier.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: Text(
                        am.abNotifier.value,
                        style: const TextStyle(fontSize: 12, color: kBlueDark),
                      ),
                    ),
                  const SectionTitle('Tốc độ & cao độ'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChipButton(
                          label: 'Tốc độ ${am.settings.speed.toStringAsFixed(2)}x',
                          icon: Icons.speed_rounded,
                          onTap: () {
                            Navigator.pop(ctx);
                            showSpeedPitchSheet(context, am);
                          },
                        ),
                        ChipButton(
                          label: 'Cao độ ${am.settings.pitch}',
                          icon: Icons.music_note_rounded,
                          onTap: () {
                            Navigator.pop(ctx);
                            showSpeedPitchSheet(context, am);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle('Mở nhanh'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChipButton(
                          label: 'Hàng đợi (${am.queue.length})',
                          icon: Icons.queue_music_rounded,
                          onTap: () {
                            Navigator.pop(ctx);
                            showQueueSheet(context, am);
                          },
                        ),
                        ChipButton(
                          label: 'Hẹn giờ: ${am.timerNotifier.value}',
                          icon: Icons.timer_outlined,
                          onTap: () {
                            Navigator.pop(ctx);
                            showSleepTimerSheet(context, am);
                          },
                        ),
                        ChipButton(
                          label: 'Âm thanh & DSP',
                          icon: Icons.graphic_eq_rounded,
                          onTap: () {
                            Navigator.pop(ctx);
                            showDspSheet(context, am);
                          },
                        ),
                        ChipButton(
                          label: 'Cài đặt phát nhạc',
                          icon: Icons.tune_rounded,
                          onTap: () {
                            Navigator.pop(ctx);
                            showPlaybackSettingsSheet(context, am);
                          },
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
    },
  );
}

/* ================= SHEET: THAO TÁC NHANH CHO 1 BÀI HÁT ================= */
Future<void> showSongActionsSheet(
  BuildContext context,
  AudioManager am,
  Song song,
  List<Song> playlist,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SheetShell(
        title: song.shortTitle,
        subtitle: '${song.type ?? "Track"} · #${song.id}',
        heightFactor: 0.5,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded, color: kBlue),
              title: const Text('Phát ngay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Dùng danh sách này làm hàng đợi mới',
                  style: TextStyle(fontSize: 11.5, color: kMuted)),
              onTap: () async {
                final index = playlist.indexOf(song);
                Navigator.pop(ctx);
                await am.playPlaylist(playlist, startIndex: index < 0 ? 0 : index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_play_next_rounded, color: kBlue),
              title: const Text('Phát tiếp theo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Chèn ngay sau bài đang phát',
                  style: TextStyle(fontSize: 11.5, color: kMuted)),
              onTap: () async {
                Navigator.pop(ctx);
                await am.enqueueNext(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: kBlue),
              title: const Text('Thêm vào cuối hàng đợi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Phát sau khi hết danh sách hiện tại',
                  style: TextStyle(fontSize: 11.5, color: kMuted)),
              onTap: () async {
                Navigator.pop(ctx);
                await am.enqueueLast(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: kBlue),
              title: const Text('Copy link bài hát',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: song.url));
                if (ctx.mounted) {
                  final messenger = ScaffoldMessenger.of(ctx);
                  Navigator.pop(ctx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã copy link bài hát')),
                  );
                }
              },
            ),
          ],
        ),
      );
    },
  );
}






/// Ghi chú nhỏ trong sheet
Widget noteBox(String text) {
  return Container(
    margin: const EdgeInsets.fromLTRB(18, 10, 18, 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kBlueSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBlueBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: kBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: kBlueDark, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kBlue : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: active ? kBlue : kLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: active ? Colors.white : kMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
