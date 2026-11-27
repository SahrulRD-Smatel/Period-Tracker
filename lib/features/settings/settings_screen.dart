// lib/features/settings/settings_screen.dart
// Setelan: profil siklus, pengingat (dengan status platform & uji notifikasi),
// keamanan (biometrik + PIN fallback), data (cadangan v3/pulihkan/hapus), tentang.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/data_actions.dart';
import '../../application/providers.dart';
import '../../core/adaptive.dart';
import '../../core/app_lock.dart';
import '../../core/dialogs.dart';
import '../../core/platform_ui.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/app_settings.dart';
import '../../domain/full_backup.dart';
import '../../notifications/scheduler.dart';

const appVersion = '0.4.0';

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
        message: 'Ditemukan ${data.periods.length} catatan haid, ${data.notes.length} catatan harian'
            '${data.loveNotes.isNotEmpty ? ', dan ${data.loveNotes.length} surat cinta' : ''}. '
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
      message: 'Riwayat haid, catatan harian, surat cinta, dan setelan akan dihapus permanen dari perangkat ini. '
          'Tindakan ini tidak bisa dibatalkan. Sebaiknya salin cadangan dulu.',
      confirmLabel: 'Hapus semua',
      destructive: true,
    );
    if (!ok) return;
    await wipeAllData(ref);
  }

  Future<void> _toggleAppLock(BuildContext context, WidgetRef ref, bool enable) async {
    final set = ref.read(settingsProvider.notifier);
    if (!enable) {
      await set.update((x) => x.copyWith(appLock: false));
      return;
    }

    final hw = await AppLockService.isHardwareSupported();
    if (hw) {
      final ok = await AppLockService.authenticateHardware();
      if (!ok) {
        if (context.mounted) _snack(context, 'Autentikasi perangkat dibatalkan.');
        return;
      }
      await set.update((x) => x.copyWith(appLock: true));
      return;
    }

    if (!context.mounted) return;
    final pin = await promptSetLocalPin(context);
    if (pin == null) return;
    await ref.read(appPinRepositoryProvider).savePin(pin);
    await set.update((x) => x.copyWith(appLock: true));
    if (context.mounted) _snack(context, 'Kunci PIN 4-angka aktif 🔒');
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final pin = await promptSetLocalPin(context);
    if (pin == null) return;
    await ref.read(appPinRepositoryProvider).savePin(pin);
    if (context.mounted) _snack(context, 'PIN cadangan berhasil disimpan 🔒');
  }

  Future<void> _testNotification(BuildContext context, AppSettings s) async {
    final ok = await NotificationScheduler.sendTestNotification(discreet: s.discreetNotifications);
    if (!context.mounted) return;
    _snack(
      context,
      ok
          ? 'Notifikasi uji coba dikirim! Periksa bilah notifikasi perangkatmu 🔔'
          : 'Gagal mengirim notifikasi. Pastikan izin notifikasi aktif di Setelan HP.',
    );
  }

  void _explain(BuildContext context) {
    showAppSheet<void>(
      context,
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
              '• Jika kamu mencatat hasil tes ovulasi positif (+), jadwal haid berikutnya langsung '
              'mengikuti tanggal ovulasi tersebut.\n\n'
              '• Hasilnya berupa rentang beserta tingkat keyakinan. Ini estimasi berbasis kalender, '
              'bukan alat kontrasepsi dan bukan diagnosis medis.',
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
    final notifSupported = NotificationScheduler.isSupportedPlatform;
    final notifStatus = NotificationScheduler.lastResult;

    final String notifStatusText;
    if (!notifSupported) {
      notifStatusText =
          'Notifikasi jadwal hanya berjalan di perangkat Android & iOS (tidak didukung di browser/desktop).';
    } else if (notifStatus.permissionDenied) {
      notifStatusText = 'Izin notifikasi belum diizinkan. Aktifkan di Setelan sistem perangkat.';
    } else if (!s.remindPeriod && !s.remindFertile) {
      notifStatusText = 'Semua pengingat sedang dimatikan.';
    } else if (notifStatus.usedInexactFallback) {
      notifStatusText =
          'Pengingat aktif (mode hemat daya / inexact). Pastikan izin notifikasi sistem aktif.';
    } else {
      notifStatusText =
          'Notifikasi dijadwalkan untuk jam 08:00 waktu lokal di perangkat Android/iOS ini.';
    }

    final sections = <Widget>[
      const SectionTitle('Tampilan'),
      GroupCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gaya antarmuka', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Otomatis mengikuti perangkatmu (iOS atau Android). Pilih salah satu untuk '
              'pratinjau gaya lain, mis. saat menjalankan di Windows.',
              style: kSmall,
            ),
            const SizedBox(height: 12),
            AdaptiveSegmented<UiStyle>(
              options: const {
                UiStyle.auto: 'Otomatis',
                UiStyle.ios: 'iOS',
                UiStyle.android: 'Android',
              },
              value: ref.watch(uiStyleProvider),
              onChanged: (v) => ref.read(uiStyleProvider.notifier).state = v,
            ),
          ],
        ),
      ),
      const SectionTitle('Siklusku'),
      GroupCard(
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
            GroupDivider(28),
            StepperTile(
              title: 'Lama haid',
              subtitle: 'Perkiraan awal',
              value: s.periodLength,
              min: kPeriodMin,
              max: kPeriodMax,
              unit: 'hari',
              onChanged: (v) => set.update((x) => x.copyWith(periodLength: v)),
            ),
            GroupDivider(28),
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
      GroupCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchRow(
              title: 'Haid akan datang',
              value: s.remindPeriod,
              onChanged: (v) => set.update((x) => x.copyWith(remindPeriod: v)),
            ),
            if (s.remindPeriod) ...[
              GroupDivider(20),
              SwitchRow(
                title: 'Tepat di hari perkiraan haid',
                subtitle: 'Pengingat pagi jam 08:00 saat haid mulai',
                value: s.remindPeriodDayOf,
                onChanged: (v) => set.update((x) => x.copyWith(remindPeriodDayOf: v)),
              ),
            ],
            GroupDivider(24),
            SwitchRow(
              title: 'Masa subur dimulai',
              value: s.remindFertile,
              onChanged: (v) => set.update((x) => x.copyWith(remindFertile: v)),
            ),
            if (s.remindFertile) ...[
              GroupDivider(20),
              SwitchRow(
                title: 'Puncak ovulasi',
                subtitle: 'Pengingat pagi jam 08:00 di hari ovulasi',
                value: s.remindOvulationDayOf,
                onChanged: (v) => set.update((x) => x.copyWith(remindOvulationDayOf: v)),
              ),
            ],
            GroupDivider(24),
            const Text('Ingatkan berapa hari sebelumnya',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            AdaptiveSegmented<int>(
              options: const {1: '1 hari', 2: '2 hari', 3: '3 hari'},
              value: s.remindDaysBefore,
              onChanged: (d) => set.update((x) => x.copyWith(remindDaysBefore: d)),
            ),
            GroupDivider(24),
            SwitchRow(
              title: 'Teks notifikasi netral',
              subtitle:
                  'Mis. "Pengingat" saja, tanpa kata haid / subur, agar privat di layar kunci',
              value: s.discreetNotifications,
              onChanged: (v) => set.update((x) => x.copyWith(discreetNotifications: v)),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  notifSupported ? PhosphorIconsFill.bellRinging : PhosphorIconsRegular.info,
                  size: 15,
                  color: notifSupported ? AppColors.rose : AppColors.mauveSoft,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(notifStatusText, style: kSmall)),
              ],
            ),
            if (notifSupported) ...[
              GroupDivider(20),
              ActionRow(
                icon: PhosphorIconsRegular.bell,
                label: 'Kirim notifikasi uji coba',
                onTap: () => _testNotification(context, s),
              ),
            ],
          ],
        ),
      ),
      const SectionTitle('Keamanan'),
      GroupCard(
        child: Column(
          children: [
            SwitchRow(
              title: 'Kunci aplikasi',
              subtitle: 'Mengunci setiap kali dibuka kembali (biometrik atau PIN 4-angka)',
              value: s.appLock,
              onChanged: (v) => _toggleAppLock(context, ref, v),
            ),
            if (s.appLock) ...[
              GroupDivider(12),
              ActionRow(
                icon: PhosphorIconsRegular.lockKey,
                label: 'Atur / ganti PIN cadangan 4-angka',
                onTap: () => _changePin(context, ref),
              ),
            ],
          ],
        ),
      ),
      const SectionTitle('Data'),
      GroupCard(
        child: Column(
          children: [
            ActionRow(
              icon: PhosphorIconsRegular.copy,
              label: 'Salin cadangan',
              onTap: () => _copyBackup(context, ref),
            ),
            GroupDivider(1),
            ActionRow(
              icon: PhosphorIconsRegular.arrowCounterClockwise,
              label: 'Pulihkan dari cadangan',
              onTap: () => _restore(context, ref),
            ),
            GroupDivider(1),
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
      GroupCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActionRow(
              icon: PhosphorIconsRegular.info,
              label: 'Cara kerja prediksi',
              onTap: () => _explain(context),
            ),
            GroupDivider(24),
            const Text('Siklusku $appVersion 🎀', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Data kesehatan pribadimu tersimpan di perangkat ini. Tidak ada iklan dan tidak ada pelacak. '
              'Perkiraan berdasarkan kalender, bukan alat kontrasepsi dan bukan diagnosis medis.',
              style: kSmall,
            ),
          ],
        ),
      ),
    ];

    return AdaptivePage(
      title: 'Setelan',
      subtitle: 'Atur siklus, pengingat, dan datamu',
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
                hintText: '{"version":3, ...}',
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
