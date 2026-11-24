// lib/features/partner/partner_screen.dart
// Tersambung dengan pasangan: undang / terima kode, atur data yang dibagikan, lihat ringkasan.
// Saat ini memakai DemoPartnerRepository (tanpa server).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/dialogs.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/partner_repository.dart';
import '../../domain/partner_models.dart';
import 'partner_widgets.dart';

class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _error = null);
    try {
      await ref.read(partnerProvider.notifier).acceptInvite(_code.text);
      _code.clear();
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _revoke({required bool viewer}) async {
    final ok = await confirmDialog(
      context,
      title: viewer ? 'Putuskan koneksi?' : 'Hentikan berbagi?',
      message: viewer
          ? 'Kamu tidak akan lagi melihat ringkasan kondisi pasanganmu.'
          : 'Koneksi akan langsung terputus seketika. Pasangan tidak akan bisa lagi melihat ringkasan kondisimu.',
      confirmLabel: viewer ? 'Putuskan' : 'Hentikan Berbagi',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(partnerProvider.notifier).revoke();
  }

  String _subtitle(PartnerState st) => switch (st.role) {
        PartnerRole.none => 'Saling mengerti & peduli dengan izin pemilik data',
        PartnerRole.owner => st.linked ? 'Kamu memegang kendali penuh apa yang dibagikan' : 'Menunggu pasangan menerima undangan',
        PartnerRole.viewer => 'Kondisi & panduan perhatian untuk pasanganmu',
      };

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(partnerProvider);
    final isDemo = ref.watch(partnerRepositoryProvider) is DemoPartnerRepository;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        BowHeader(title: 'Pasangan', subtitle: _subtitle(st)),
        const SizedBox(height: 16),
        if (isDemo) ...[
          const PinkCard(
            color: AppColors.petal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIconsRegular.flask, color: AppColors.rose),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mode demo: belum terhubung ke server. Alur dan tampilan sudah lengkap; '
                    'sinkronisasi nyata menyusul.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        switch (st.role) {
          PartnerRole.none => _none(),
          PartnerRole.owner => st.linked ? _ownerLinked(st) : _ownerInvite(st),
          PartnerRole.viewer => _viewer(st),
        },
      ],
    );
  }

  // ---------- belum terhubung ----------
  Widget _none() => Column(
        children: [
          PinkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.petal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(PhosphorIconsFill.usersThree, color: AppColors.rose, size: 28),
                ),
                const SizedBox(height: 8),
                Text('Saling Mengerti & Peduli', style: kHeading.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                const Text(
                  'Bantu pasangan lebih peka memahami saat kamu butuh istirahat '
                  'tanpa perlu repot menjelaskan. Kamu memegang kendali penuh.',
                  style: kSmall,
                ),
                const SizedBox(height: 12),
                const _Check('Hanya kondisi umum & kebutuhan energi harian'),
                const _Check('Masa subur opsional & catatan tetap rahasia'),
                const _Check('Bisa dihentikan kapan saja dengan aman'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PinkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aku pemilik data', style: kHeading.copyWith(fontSize: 20)),
                const SizedBox(height: 6),
                const Text('Buat kode undangan untuk pasanganmu.', style: kSmall),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => ref.read(partnerProvider.notifier).createInvite(),
                    child: const Text('Buat kode undangan'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PinkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aku pasangan', style: kHeading.copyWith(fontSize: 20)),
                const SizedBox(height: 6),
                const Text('Masukkan kode dari pasanganmu.', style: kSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  maxLength: 8,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'KODE 8 KARAKTER',
                    errorText: _error,
                    filled: true,
                    fillColor: AppColors.blush,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.ribbon),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.ribbon),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _accept, child: const Text('Hubungkan')),
                ),
              ],
            ),
          ),
        ],
      );

  // ---------- pemilik: menunggu ----------
  Widget _ownerInvite(PartnerState st) => PinkCard(
        child: Column(
          children: [
            const Text('Kode undanganmu', style: kSmall),
            const SizedBox(height: 8),
            Text(
              st.inviteCode ?? '',
              style: kHeading.copyWith(fontSize: 36, letterSpacing: 4),
            ),
            const SizedBox(height: 6),
            const Text('Berlaku 24 jam, sekali pakai.', style: kSmall),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: st.inviteCode ?? ''));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Kode disalin 🎀')));
                },
                icon: const Icon(PhosphorIconsRegular.copy),
                label: const Text('Salin kode'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(partnerProvider.notifier).revoke(),
                child: const Text('Batalkan undangan'),
              ),
            ),
            if (st.demo)
              TextButton(
                onPressed: () => ref.read(partnerProvider.notifier).simulateAccepted(),
                child: const Text('Demo: anggap pasangan sudah menerima'),
              ),
          ],
        ),
      );

  // ---------- pemilik: tersambung ----------
  Widget _ownerLinked(PartnerState st) {
    final notifier = ref.read(partnerProvider.notifier);
    final summary = ref.watch(homeSummaryProvider);
    final today = ref.watch(todayProvider);
    return Column(
      children: [
        PinkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Terhubung dengan ${st.partnerName ?? 'pasangan'} 💞', style: kHeading.copyWith(fontSize: 20)),
              const SizedBox(height: 12),
              SwitchRow(
                title: 'Fase siklus & energi',
                subtitle: 'Menstruasi, pemulihan energi, PMS…',
                value: st.flags.phase,
                onChanged: (v) => notifier.setFlags(st.flags.copyWith(phase: v)),
              ),
              const Divider(height: 24, color: AppColors.petal),
              SwitchRow(
                title: 'Perkiraan haid',
                subtitle: 'Bantu pasangan siap mendampingi saat haid datang',
                value: st.flags.nextPeriod,
                onChanged: (v) => notifier.setFlags(st.flags.copyWith(nextPeriod: v)),
              ),
              const Divider(height: 24, color: AppColors.petal),
              SwitchRow(
                title: 'Masa subur & ovulasi (Opsional)',
                subtitle: 'Matikan bila tidak ingin berbagi detail biologis intim',
                value: st.flags.fertileWindow,
                onChanged: (v) => notifier.setFlags(st.flags.copyWith(fertileWindow: v)),
              ),
              const SizedBox(height: 10),
              const Text('100% rahasia pribadimu: gejala fisik, mood, catatan diary, dan riwayat tidak pernah dibagikan.', style: kSmall),
            ],
          ),
        ),
        const SectionTitle('Tampilan di HP pasangan'),
        if (summary == null)
          const PinkCard(child: Text('Catat haid dulu agar ada yang bisa dibagikan.', style: kSmall))
        else
          PartnerSnapshotView(
            snapshot: buildSnapshot(summary, st.flags, DateTime.now()),
            today: today,
          ),
        const SizedBox(height: 14),
        CareChecklistCard(phase: summary?.phase, partnerName: st.partnerName),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            onPressed: () => _revoke(viewer: false),
            child: const Text('Hentikan Berbagi dengan Pasangan'),
          ),
        ),
      ],
    );
  }

  // ---------- pasangan (pelihat) ----------
  Widget _viewer(PartnerState st) {
    final snap = st.snapshot;
    final today = ref.watch(todayProvider);
    return Column(
      children: [
        if (snap == null)
          const PinkCard(child: Text('Belum ada data dari pasanganmu.', style: kSmall))
        else ...[
          PartnerSnapshotView(snapshot: snap, today: today),
          const SizedBox(height: 14),
          CareChecklistCard(phase: snap.phase, partnerName: st.partnerName),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            onPressed: () => _revoke(viewer: true),
            child: const Text('Putuskan koneksi'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Informasi ini bersifat pribadi. Hormati keputusan dan privasi pasanganmu.',
          textAlign: TextAlign.center,
          style: kSmall,
        ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  final String text;
  const _Check(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(PhosphorIconsFill.checkCircle, size: 18, color: AppColors.rose),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(height: 1.3))),
          ],
        ),
      );
}
