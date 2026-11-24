// lib/features/settings/settings_screen.dart
// Setelan: profil siklus, pengingat, keamanan, data (cadangan/pulihkan/hapus), tentang.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/data_actions.dart';
import '../../application/providers.dart';
import '../../core/app_lock.dart';
import '../../core/dialogs.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/app_settings.dart';
import '../../domain/full_backup.dart';

const appVersion = '0.3.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _copyBackup(BuildContext context, WidgetRef ref) async {
    await Clipboard.setData(ClipboardData(text: buildBackupJson(ref)));
    if (context.mounted) {
      _snack(context, 'Cadangan disalin. Simpan di tempat aman (catatan pribadi / email ke diri sendiri).');
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    try {
      final data = importFullBackup(text.trim());
      final ok = await confirmDialog(
        context,
        title: 'Ganti data sekarang?',
        message: 'Ditemukan ${data.periods.length} catatan haid dan ${data.notes.length} catatan harian. '
            'Data di perangkat ini akan diganti.',
        confirmLabel: 'Pulihkan',
      );
      if (!ok) return;
      await restoreBackup(ref, data);
      if (context.mounted) _snack(context, 'Data berhasil dipulihkan 🎀');
    } on FormatException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus semua data?',
      message: 'Riwayat haid, catatan harian, dan setelan akan dihapus permanen dari perangkat ini. '
          'Tindakan ini tidak bisa dibatalkan. Sebaiknya salin cadangan dulu.',
      confirmLabel: 'Hapus semua',
      destructive: true,
    );
    if (!ok) return;
    await wipeAllData(ref);
  }

  void _explain(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cara kerja prediksi', style: kHeading.copyWith(fontSize: 22)),
            const SizedBox(height: 12),
            const Text(
              '• Perkiraan dihitung dari hari pertama haid yang benar-benar terjadi, jadi bila haid '
              'telat seminggu, jadwal berikutnya ikut bergeser.\n\n'
              '• Panjang siklus diambil dari median 6 siklus terakhir, supaya satu siklus yang '
              'telat atau maju tidak langsung mengubah semuanya.\n\n'
              '• Ovulasi diperkirakan ±14 hari sebelum haid berikutnya, bukan "hari ke-14". '
              'Masa subur = 5 hari sebelum sampai 1 hari sesudah ovulasi.\n\n'
              '• Hasilnya berupa rentang beserta tingkat keyakinan. Makin banyak siklus tercatat, '
              'makin akurat.\n\n'
              '• Ini estimasi berbasis kalender, bukan alat kontrasepsi dan bukan diagnosis. '
              'Bila haid sangat tidak teratur atau terlambat lama, konsultasikan ke dokter.',
              style: TextStyle(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final set = ref.read(settingsProvider.notifier);

    final sections = <Widget>[
      const BowHeader(title: 'Setelan', subtitle: 'Atur siklus, pengingat, dan datamu'),
      const SectionTitle('Siklusku'),
      PinkCard(
        child: Column(
          children: [
            StepperTile(
              title: 'Panjang siklus',
              subtitle: 'Perkiraan awal',
              value: s.cycleLength,
              min: kCycleMin,
              max: kCycleMax,
              unit: 'hari',
              onChanged: (v) => set.update((x) => x.copyWith(cycleLength: v)),
            ),
            const Divider(height: 28, color: AppColors.petal),
            StepperTile(
              title: 'Lama haid',
              subtitle: 'Perkiraan awal',
              value: s.periodLength,
              min: kPeriodMin,
              max: kPeriodMax,
              unit: 'hari',
              onChanged: (v) => set.update((x) => x.copyWith(periodLength: v)),
            ),
            const Divider(height: 28, color: AppColors.petal),
            StepperTile(
              title: 'Fase luteal',
              subtitle: 'Ovulasi → haid berikutnya. Biarkan 14 bila ragu.',
              value: s.lutealLength,
              min: kLutealMin,
              max: kLutealMax,
              unit: 'hari',
              onChanged: (v) => set.update((x) => x.copyWith(lutealLength: v)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nilai ini hanya dipakai saat datamu masih sedikit. Setelah beberapa siklus tercatat, '
              'perkiraan mengikuti riwayatmu sendiri.',
              style: kSmall,
            ),
          ],
        ),
      ),
      const SectionTitle('Pengingat'),
      PinkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchRow(
              title: 'Haid akan datang',
              value: s.remindPeriod,
              onChanged: (v) => set.update((x) => x.copyWith(remindPeriod: v)),
            ),
            if (s.remindPeriod) ...[
              const Divider(height: 20, color: AppColors.petal),
              SwitchRow(
                title: 'Tepat di hari perkiraan haid',
                subtitle: 'Pengingat pagi jam 08:00 saat haid mulai',
                value: s.remindPeriodDayOf,
                onChanged: (v) => set.update((x) => x.copyWith(remindPeriodDayOf: v)),
              ),
            ],
            const Divider(height: 24, color: AppColors.petal),
            SwitchRow(
              title: 'Masa subur dimulai',
              value: s.remindFertile,
              onChanged: (v) => set.update((x) => x.copyWith(remindFertile: v)),
            ),
            if (s.remindFertile) ...[
              const Divider(height: 20, color: AppColors.petal),
              SwitchRow(
                title: 'Puncak ovulasi',
                subtitle: 'Pengingat pagi jam 08:00 di hari ovulasi',
                value: s.remindOvulationDayOf,
                onChanged: (v) => set.update((x) => x.copyWith(remindOvulationDayOf: v)),
              ),
            ],
            const Divider(height: 24, color: AppColors.petal),
            const Text('Ingatkan berapa hari sebelumnya',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [1, 2, 3])
                  PinkChoiceChip(
                    label: '$d hari',
                    selected: s.remindDaysBefore == d,
                    onTap: () => set.update((x) => x.copyWith(remindDaysBefore: d)),
                  ),
              ],
            ),
            const Divider(height: 24, color: AppColors.petal),
            SwitchRow(
              title: 'Teks notifikasi netral',
              subtitle:
                  'Mis. "Pengingat" saja, tanpa kata haid / subur, agar privat di layar kunci',
              value: s.discreetNotifications,
              onChanged: (v) => set.update((x) => x.copyWith(discreetNotifications: v)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(PhosphorIconsFill.bellRinging,
                    size: 14, color: AppColors.rose),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Notifikasi aktif. Pastikan izin notifikasi diberikan di pengaturan perangkat.',
                    style: kSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SectionTitle('Keamanan'),
      PinkCard(
        child: SwitchRow(
          title: 'Kunci aplikasi',
          subtitle: 'Face ID, sidik jari, atau PIN perangkat',
          value: s.appLock,
          onChanged: (v) async {
            if (v) {
              final ok = await AppLockService.authenticate();
              if (!ok) return;
            }
            set.update((x) => x.copyWith(appLock: v));
          },
        ),
      ),
      const SectionTitle('Data'),
      PinkCard(
        child: Column(
          children: [
            ActionRow(
              icon: PhosphorIconsRegular.copy,
              label: 'Salin cadangan',
              onTap: () => _copyBackup(context, ref),
            ),
            const Divider(height: 1, color: AppColors.petal),
            ActionRow(
              icon: PhosphorIconsRegular.arrowCounterClockwise,
              label: 'Pulihkan dari cadangan',
              onTap: () => _restore(context, ref),
            ),
            const Divider(height: 1, color: AppColors.petal),
            ActionRow(
              icon: PhosphorIconsRegular.trash,
              label: 'Hapus semua data',
              danger: true,
              onTap: () => _wipe(context, ref),
            ),
          ],
        ),
      ),
      const SectionTitle('Tentang'),
      PinkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActionRow(
              icon: PhosphorIconsRegular.info,
              label: 'Cara kerja prediksi',
              onTap: () => _explain(context),
            ),
            const Divider(height: 24, color: AppColors.petal),
            const Text('Siklusku $appVersion 🎀', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Datamu tersimpan di perangkat ini. Tidak ada iklan dan tidak ada pelacak. '
              'Perkiraan berdasarkan kalender, bukan alat kontrasepsi dan bukan diagnosis medis.',
              style: kSmall,
            ),
          ],
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        for (var i = 0; i < sections.length; i++)
          sections[i]
              .animate(delay: (i * 50).ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.04, curve: Curves.easeOut),
      ],
    );
  }
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Pulihkan dari cadangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tempel teks cadangan yang pernah kamu salin.', style: kSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"version":2, ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Pulihkan'),
          ),
        ],
      );
}
