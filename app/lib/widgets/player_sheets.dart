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
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * heightFactor,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? kBlue : kBlueSoft,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: active ? kBlue : kBlueBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: active ? Colors.white : kBlueDark),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : kBlueDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// Thông báo khi danh sách trống
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

/// Hộp ghi chú nhỏ màu xanh nhạt
Widget noteBox(String text) {
  return Container(
    margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kBlueSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBlueBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: kBlueDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: kBlueDark,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

/* ================= SHEET: HÀNG ĐỢI ================= */
Future<void> showQueueSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return ValueListenableBuilder<List<Song>>(
        valueListenable: am.currentPlaylistNotifier,
        builder: (context, list, _) {
          final currentIndex = am.currentIndexNotifier.value;
          final currentTitle = am.currentSongNotifier.value?.shortTitle ?? '—';
          return SheetShell(
            title: 'Hàng đợi',
            subtitle: '${list.length} bài · đang phát: $currentTitle',
            heightFactor: 0.86,
            actions: <Widget>[
              ChipButton(
                label: 'Copy playlist JSON',
                icon: Icons.copy_rounded,
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: am.queueAsJson()),
                  );
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Đã copy playlist JSON vào clipboard'),
                      ),
                    );
                  }
                },
              ),
              ChipButton(
                label: 'Xoá sạch',
                icon: Icons.delete_sweep_rounded,
                onTap: () async {
                  await am.clearQueue();
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
              ),
            ],
            child: list.isEmpty
                ? emptyHint(
                    'Hàng đợi đang trống.\n'
                    'Bấm một bài trong Thư viện để bắt đầu nghe.',
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    children: <Widget>[
                      noteBox(
                        'Giữ và kéo biểu tượng ≡ để đổi thứ tự · '
                        'bấm X để xoá bài khỏi hàng đợi.',
                      ),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: list.length,
                        onReorder: am.reorderQueue,
                        itemBuilder: (context, index) {
                          final song = list[index];
                          return queueTile(
                            song: song,
                            index: index,
                            isCurrent: index == currentIndex,
                            onPlay: () => am.playSong(song, list),
                            onDelete: () => am.removeFromQueue(index),
                          );
                        },
                      ),
                    ],
                  ),
          );
        },
      );
    },
  );
}

/// Một dòng trong hàng đợi (kéo–thả đổi thứ tự)
Widget queueTile({
  required Song song,
  required int index,
  required bool isCurrent,
  required VoidCallback onPlay,
  required VoidCallback onDelete,
}) {
  return Container(
    key: ValueKey<String>('queue-${song.id}-$index'),
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    decoration: BoxDecoration(
      color: isCurrent ? kBlueSoft : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isCurrent ? kBlueBorder : kLine),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPlay,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        child: Row(
          children: <Widget>[
            Icon(
              isCurrent ? Icons.volume_up_rounded : Icons.music_note_rounded,
              size: 16,
              color: isCurrent ? kBlue : kMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    song.shortTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: isCurrent ? kBlueDark : kTextDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artistGuess,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: kMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: kMuted,
              tooltip: 'Xoá khỏi hàng đợi',
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 20,
                  color: kMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/* ================= SHEET: HẸN GIỜ TẮT NHẠC ================= */
Future<void> showSleepTimerSheet(BuildContext context, AudioManager am) {
  var customMinutes = 30;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          void refresh() => setSheetState(() {});
          return SheetShell(
            title: 'Hẹn giờ tắt nhạc',
            subtitle: 'Tự dừng phát sau khoảng thời gian bạn chọn',
            heightFactor: 0.72,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionTitle('Chọn nhanh'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final int m in <int>[
                          5,
                          10,
                          15,
                          20,
                          30,
                          45,
                          60,
                          90,
                          120
                        ])
                          ChipButton(
                            label: '$m phút',
                            icon: Icons.timer_outlined,
                            onTap: () {
                              am.startSleepTimer(m);
                              refresh();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SectionTitle('Tuỳ chỉnh'),
                  LabeledSlider(
                    label: 'Thời lượng hẹn giờ',
                    value: customMinutes.toDouble(),
                    min: 1,
                    max: 180,
                    divisions: 179,
                    valueText: '$customMinutes phút',
                    onChanged: (v) {
                      setSheetState(() => customMinutes = v.round());
                    },
                  ),
                  timerActionRow(
                    label: 'Hẹn giờ $customMinutes phút',
                    onStart: () {
                      am.startSleepTimer(customMinutes);
                      refresh();
                    },
                    onCancel: () {
                      am.cancelSleepTimer();
                      refresh();
                    },
                  ),
                  const SectionTitle('Tuỳ chọn'),
                  SwitchRow(
                    title: 'Phát hết bài hiện tại rồi mới tắt',
                    subtitle: 'Không cắt ngang bài đang phát',
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
                    'Mẹo: bật "Phát hết bài hiện tại rồi mới tắt" khi nghe '
                    'album hoặc nhạc live để không bị cắt giữa bài.',
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

/// Hàng nút "Hẹn giờ" + "Tắt hẹn giờ" dùng trong sheet hẹn giờ
Widget timerActionRow({
  required String label,
  required VoidCallback onStart,
  required VoidCallback onCancel,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
    child: Row(
      children: <Widget>[
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kBlue,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onStart,
            child: Text(label),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: kBlueDark,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
            side: const BorderSide(color: kBlueBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onCancel,
          child: const Text('Tắt hẹn giờ'),
        ),
      ],
    ),
  );
}

/// Nút tròn dùng cho điều khiển phát (previous / play / next)
Widget roundIconButton({
  required IconData icon,
  required VoidCallback onTap,
  bool primary = false,
  double size = 48,
}) {
  return Material(
    color: primary ? kBlue : Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primary ? kBlue : kLine),
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: primary ? Colors.white : kBlueDark,
        ),
      ),
    ),
  );
}

/* ================= SHEET: TỐC ĐỘ & CAO ĐỘ ================= */
Future<void> showSpeedPitchSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final bool pitchOk = am.pitchSupported;
          return SheetShell(
            title: 'Tốc độ & Cao độ',
            subtitle: 'Nghe nhanh/chậm mà vẫn rõ lời, đổi tông khi tập hát',
            heightFactor: 0.72,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionTitle('Tốc độ phát (giữ nguyên giọng)'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final double sp in <double>[
                          0.5,
                          0.75,
                          1.0,
                          1.25,
                          1.5,
                          2.0
                        ])
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
                      children: <Widget>[
                        for (final int p in <int>[-6, -3, -1, 0, 1, 3, 6])
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
                    pitchOk
                        ? 'Tốc độ xử lý ở tầng hệ điều hành nên giọng hát không '
                              'bị biến dạng. Cao độ áp dụng cho cả bài đang phát.'
                        : 'Máy này không hỗ trợ đổi cao độ (pitch) — hãy dùng '
                              'Tốc độ, hoặc chờ bản DSP native.',
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
    builder: (sheetContext) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SheetShell(
            title: 'Âm thanh & DSP',
            subtitle: 'Chuyển bài mượt, gapless, xử lý ngắt hệ thống',
            heightFactor: 0.82,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionTitle('Chuyển bài mượt mà'),
                  SwitchRow(
                    title: 'Phát liền mạch (Gapless)',
                    subtitle: 'iOS dùng AVQueuePlayer nên gần như không có '
                        'khoảng lặng giữa 2 bài',
                    value: s.gapless,
                    onChanged: (v) {
                      setSheetState(() => s.gapless = v);
                      s.save();
                    },
                  ),
                  LabeledSlider(
                    label: 'Chuyển bài mượt (fade-out rồi sang bài mới)',
                    value: s.crossfadeSeconds,
                    min: 0,
                    max: 12,
                    divisions: 12,
                    valueText: s.crossfadeSeconds < 0.5
                        ? 'Tắt'
                        : '${s.crossfadeSeconds.toStringAsFixed(0)}s',
                    onChanged: (v) {
                      setSheetState(() => s.crossfadeSeconds = v);
                      s.save();
                    },
                  ),
                  LabeledSlider(
                    label: 'Fade in/out khi Play / Pause',
                    value: s.fadeSeconds,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    valueText: '${s.fadeSeconds.toStringAsFixed(1)}s',
                    onChanged: (v) {
                      setSheetState(() => s.fadeSeconds = v);
                      s.save();
                    },
                  ),
                  const SectionTitle('Âm lượng & tua'),
                  LabeledSlider(
                    label: 'Âm lượng',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final int st in <int>[5, 10, 15, 30])
                          ChipButton(
                            label: 'Bước tua $st giây',
                            icon: Icons.fast_forward_rounded,
                            active: s.seekStep == st,
                            onTap: () {
                              setSheetState(() => s.seekStep = st);
                              s.save();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SectionTitle('Thiết bị & hệ thống'),
                  SwitchRow(
                    title: 'Dừng khi rút tai nghe / mất Bluetooth',
                    subtitle: 'Không tự phát ra loa ngoài khi bạn tháo tai nghe',
                    value: s.pauseOnUnplug,
                    onChanged: (v) {
                      setSheetState(() => s.pauseOnUnplug = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Tự giảm âm khi có thông báo (Ducking)',
                    subtitle: 'Nhạc nhỏ lại khi có tin nhắn/cuộc gọi rồi tự hồi',
                    value: s.duckOnNotification,
                    onChanged: (v) {
                      setSheetState(() => s.duckOnNotification = v);
                      s.save();
                    },
                  ),
                  noteBox(
                    'EQ nhiều dải, âm thanh vòm và ReplayGain cần Audio Unit '
                    'native (AVAudioEngine) nên bản iOS dùng những gì hệ thống '
                    'xử lý sẵn. Bản web đã có EQ 10 dải đầy đủ.',
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

/* ================= SHEET: CÀI ĐẶT PHÁT NHẠC ================= */
Future<void> showPlaybackSettingsSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final s = am.settings;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SheetShell(
            title: 'Cài đặt phát nhạc',
            subtitle: 'Hành vi phát, phiên nghe và dữ liệu lưu trong máy',
            heightFactor: 0.86,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionTitle('Chế độ phát'),
                  SwitchRow(
                    title: 'Tự bật xáo trộn khi bấm phát',
                    value: s.autoShuffleOnPlay,
                    onChanged: (v) {
                      setSheetState(() => s.autoShuffleOnPlay = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Xáo trộn thông minh',
                    subtitle: 'Không lặp bài vừa nghe và tránh 2 bài cùng ca sĩ '
                        'đứng gần nhau',
                    value: s.smartShuffle,
                    onChanged: (v) {
                      setSheetState(() => s.smartShuffle = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Tự phát bài tiếp theo',
                    value: s.autoplayNext,
                    onChanged: (v) {
                      setSheetState(() => s.autoplayNext = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Nút lùi về đầu bài khi đã phát quá 3 giây',
                    value: s.prevBackToStart,
                    onChanged: (v) {
                      setSheetState(() => s.prevBackToStart = v);
                      s.save();
                    },
                  ),
                  const SectionTitle('Phiên nghe'),
                  SwitchRow(
                    title: 'Ghi nhớ bài và vị trí đang nghe',
                    subtitle: 'Mở lại app là tiếp tục đúng giây đã nghe dở',
                    value: s.resumeLastPosition,
                    onChanged: (v) {
                      setSheetState(() => s.resumeLastPosition = v);
                      s.save();
                    },
                  ),
                  SwitchRow(
                    title: 'Tự phát tiếp khi mở app',
                    value: s.autoPlayOnResume,
                    onChanged: (v) {
                      setSheetState(() => s.autoPlayOnResume = v);
                      s.save();
                    },
                  ),
                  const SectionTitle('Dữ liệu'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
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
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ),
                  noteBox(
                    'Cài đặt được lưu trong máy (SharedPreferences) nên giữ '
                    'nguyên sau khi tắt app. Danh sách bài vẫn đọc trực tiếp '
                    'từ GitHub Pages.',
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

/* ================= SHEET: ĐIỀU KHIỂN NHANH ================= */
Future<void> showQuickControlsSheet(BuildContext context, AudioManager am) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          void refresh() => setSheetState(() {});
          final song = am.currentSongNotifier.value;
          return SheetShell(
            title: 'Điều khiển nhanh',
            subtitle: song == null
                ? 'Chưa có bài hát nào đang phát'
                : 'Đang phát: ${song.shortTitle}',
            heightFactor: 0.78,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionTitle('Chế độ phát'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ChipButton(
                          label: am.isShuffleOn ? 'Xáo trộn: Bật' : 'Xáo trộn',
                          icon: Icons.shuffle_rounded,
                          active: am.isShuffleOn,
                          onTap: () async {
                            await am.setShuffle(!am.isShuffleOn);
                            refresh();
                          },
                        ),
                        ChipButton(
                          label: 'Lặp: ${am.repeatLabel}',
                          icon: Icons.repeat_rounded,
                          active: am.repeatMode != RepeatModeApp.off,
                          onTap: () async {
                            await am.cycleRepeat();
                            refresh();
                          },
                        ),
                        ChipButton(
                          label: am.hasAbRepeat ? 'Lặp A-B: Bật' : 'Lặp A-B',
                          icon: Icons.repeat_on_rounded,
                          active: am.hasAbRepeat,
                          onTap: () async {
                            final msg = await am.cycleAbRepeat();
                            refresh();
                            if (msg.isNotEmpty && sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          },
                        ),
                        ChipButton(
                          label: 'Hẹn giờ: ${am.timerNotifier.value}',
                          icon: Icons.timer_outlined,
                          active: am.hasSleepTimer,
                          onTap: () => showSleepTimerSheet(sheetContext, am),
                        ),
                        ChipButton(
                          label:
                              'Tốc độ ${am.settings.speed.toStringAsFixed(2)}x',
                          icon: Icons.speed_rounded,
                          active: (am.settings.speed - 1.0).abs() > 0.001,
                          onTap: () => showSpeedPitchSheet(sheetContext, am),
                        ),
                        ChipButton(
                          label: 'Âm thanh & DSP',
                          icon: Icons.graphic_eq_rounded,
                          onTap: () => showDspSheet(sheetContext, am),
                        ),
                        ChipButton(
                          label: 'Hàng đợi (${am.queue.length})',
                          icon: Icons.queue_music_rounded,
                          onTap: () => showQueueSheet(sheetContext, am),
                        ),
                        ChipButton(
                          label: 'Cài đặt chi tiết',
                          icon: Icons.tune_rounded,
                          onTap: () =>
                              showPlaybackSettingsSheet(sheetContext, am),
                        ),
                      ],
                    ),
                  ),

                  const SectionTitle('Điều khiển phát'),
                  ValueListenableBuilder<bool>(
                    valueListenable: am.isPlayingNotifier,
                    builder: (context, playing, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            roundIconButton(
                              icon: Icons.skip_previous_rounded,
                              onTap: () => am.playPrevious(),
                            ),
                            roundIconButton(
                              icon: Icons.replay_rounded,
                              onTap: () =>
                                  am.skipSeconds(-am.settings.seekStep),
                            ),
                            roundIconButton(
                              icon: playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              primary: true,
                              size: 60,
                              onTap: () => am.togglePlayPause(),
                            ),
                            roundIconButton(
                              icon: Icons.forward_rounded,
                              onTap: () => am.skipSeconds(am.settings.seekStep),
                            ),
                            roundIconButton(
                              icon: Icons.skip_next_rounded,
                              onTap: () => am.playNext(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: ValueListenableBuilder<String>(
                      valueListenable: am.statusNotifier,
                      builder: (context, status, _) {
                        if (status.isEmpty) return const SizedBox.shrink();
                        return Text(
                          status,
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        );
                      },
                    ),
                  ),
                  noteBox(
                    'Bấm giữ một bài trong Thư viện để mở thao tác nhanh: '
                    'Phát ngay, Phát tiếp theo, Thêm vào cuối hàng đợi, '
                    'Copy link nhạc.',
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

/* ================= SHEET: THAO TÁC NHANH CHO MỘT BÀI HÁT ================= */
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
    builder: (sheetContext) {
      final int queueIndex =
          am.queue.indexWhere((Song e) => e.id == song.id && e.url == song.url);
      return SheetShell(
        title: song.shortTitle,
        subtitle: '${song.artistGuess} · ${song.type ?? 'Không rõ thể loại'}',
        heightFactor: 0.52,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionTitle('Thao tác'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ChipButton(
                      label: 'Phát ngay',
                      icon: Icons.play_arrow_rounded,
                      active: true,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        am.playSong(song, playlist);
                      },
                    ),
                    ChipButton(
                      label: 'Phát tiếp theo',
                      icon: Icons.playlist_play_rounded,
                      onTap: () async {
                        await am.enqueueNext(song);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                    ChipButton(
                      label: 'Thêm vào cuối hàng đợi',
                      icon: Icons.playlist_add_rounded,
                      onTap: () async {
                        await am.enqueueLast(song);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                    if (queueIndex >= 0)
                      ChipButton(
                        label: 'Xoá khỏi hàng đợi (#${queueIndex + 1})',
                        icon: Icons.delete_outline_rounded,
                        onTap: () async {
                          await am.removeFromQueue(queueIndex);
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                      ),
                    ChipButton(
                      label: 'Copy link nhạc',
                      icon: Icons.link_rounded,
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: song.url));
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Đã copy link bài hát'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              noteBox(
                'Bấm giữ bài hát bất kỳ trong danh sách Thư viện để mở lại '
                'bảng thao tác nhanh này.',
              ),
            ],
          ),
        ),
      );
    },
  );
}
