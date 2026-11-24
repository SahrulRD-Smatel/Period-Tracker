// lib/features/home/home_screen.dart
// Beranda: cincin siklus (hari ke-N), hitung mundur haid, status masa subur, aksi pencatatan.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/formatters.dart';
import '../../core/phase_style.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/cycle_engine.dart';
import '../../domain/home_summary.dart';
import 'cycle_ring.dart';
import 'love_letter_dialog.dart';
import '../../core/note_labels.dart';
import '../log/log_screen.dart';
import 'log_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final logs = ref.watch(periodLogsProvider);
    final p = ref.watch(predictionProvider);
    final s = ref.watch(homeSummaryProvider);

    final Widget body;
    if (logs.isEmpty) {
      body = const _EmptyState();
    } else if (p == null || s == null) {
      body = const PinkCard(
        child: Text(
          'Data belum bisa dihitung. Periksa tanggal perangkat atau catatan haidmu.',
          style: kSmall,
        ),
      );
    } else {
      body = Column(
        children: [
          _RingCard(prediction: p, summary: s)
              .animate()
              .scale(
                begin: const Offset(0.92, 0.92),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 14),
          const _LoveLetterEnvelopeCard()
              .animate(delay: 60.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 14),
          _CountdownCard(summary: s)
              .animate(delay: 90.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 14),
          _FertileCard(summary: s)
              .animate(delay: 160.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
          if (s.lateness != Lateness.none) ...[
            const SizedBox(height: 14),
            _AdviceCard(lateness: s.lateness)
                .animate(delay: 220.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.06, curve: Curves.easeOut),
          ],
          const SizedBox(height: 14),
          const _LogActions()
              .animate(delay: 280.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 14),
          const _TodayNoteCard()
              .animate(delay: 340.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        BowHeader(subtitle: fmtFull(today))
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: -0.05, curve: Curves.easeOut),
        const SizedBox(height: 18),
        body,
        const SizedBox(height: 20),
        const Text(
          'Perkiraan berdasarkan kalender, bukan alat kontrasepsi dan bukan diagnosis medis.',
          textAlign: TextAlign.center,
          style: kSmall,
        ),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        children: [
          PinkCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.petal, AppColors.petalGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowDiffuse,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(PhosphorIconsFill.flowerLotus, color: AppColors.rose, size: 40),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 14),
                Text('Selamat datang', style: kHeading.copyWith(fontSize: 26, letterSpacing: -0.6))
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 8),
                const Text(
                  'Mulai dengan mencatat hari pertama haid terakhirmu. '
                  'Makin banyak data, makin akurat perkiraannya.',
                  textAlign: TextAlign.center,
                  style: kSmall,
                ).animate(delay: 180.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => pickAndLogPeriodStart(context, ref),
                    child: const Text('Catat haid terakhir'),
                  ),
                ).animate(delay: 260.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _LoveLetterEnvelopeCard()
              .animate(delay: 320.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
        ],
      );
}

List<Color> _ringColors(CycleWindow w) {
  final n = w.nextPeriodStart.difference(w.periodStart).inDays;
  return [
    for (var i = 0; i < n; i++)
      phaseStyle(w.phaseOf(w.periodStart.add(Duration(days: i)))).color,
  ];
}

class _RingCard extends StatelessWidget {
  final CyclePrediction prediction;
  final HomeSummary summary;
  const _RingCard({required this.prediction, required this.summary});

  @override
  Widget build(BuildContext context) {
    final st = phaseStyle(summary.phase);
    return PinkCard(
      child: Column(
        children: [
          CycleRing(
            dayColors: _ringColors(prediction.current),
            currentIndex: summary.cycleDay - 1,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Hari ke-', style: kSmall),
                const SizedBox(height: 2),
                Text(
                  '${summary.cycleDay}',
                  style: kHeading.copyWith(
                    fontSize: 66,
                    height: 1.0,
                    letterSpacing: -2.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                PhaseChip(
                  label: st.label,
                  icon: st.icon,
                  color: st.color,
                  onColor: st.onColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.petal.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.ribbon.withValues(alpha: 0.4)),
            ),
            child: Text(
              st.hint,
              textAlign: TextAlign.center,
              style: kSmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.mauve,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final HomeSummary summary;
  const _CountdownCard({required this.summary});

  String get _big {
    final d = summary.daysUntilPeriod;
    if (d > 1) return '$d hari lagi';
    if (d == 1) return 'Besok';
    if (d == 0) return 'Hari ini';
    return 'Terlambat ${-d} hari';
  }

  String get _confidence => switch (summary.confidence) {
        Confidence.low => 'masih perkiraan awal (data sedikit)',
        Confidence.medium => 'cukup andal',
        Confidence.high => 'andal (siklusmu konsisten)',
      };

  @override
  Widget build(BuildContext context) => PinkCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconBubble(
              icon: PhosphorIconsFill.drop,
              color: AppColors.rose,
              onColor: AppColors.white,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.daysUntilPeriod >= 0 ? 'Haid berikutnya' : 'Haid belum datang',
                    style: kSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(_big, style: kHeading.copyWith(fontSize: 26, letterSpacing: -0.8)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.petal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Rentang perkiraan: ${fmtRange(summary.periodEarliest, summary.periodLatest)}',
                      style: kSmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Keyakinan: $_confidence', style: kSmall),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FertileCard extends StatelessWidget {
  final HomeSummary summary;
  const _FertileCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final String title;
    final String detail;
    if (s.fertileStatus == FertileStatus.ongoing) {
      title = 'Sedang masa subur';
      detail = 'Ovulasi diperkirakan ${fmtDayMonth(s.ovulation!)} · '
          'subur sampai ${fmtDayMonth(s.fertileEnd!)}';
    } else if (s.fertileStatus == FertileStatus.upcoming) {
      title = s.daysUntilFertile == 1
          ? 'Masa subur besok'
          : 'Masa subur ${s.daysUntilFertile} hari lagi';
      detail = 'Ovulasi diperkirakan ${fmtDayMonth(s.ovulation!)}';
    } else {
      title = 'Masa subur belum bisa diperkirakan';
      detail = 'Catat tanggal haid yang sebenarnya agar perkiraan diperbarui.';
    }
    return PinkCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(
            icon: PhosphorIconsFill.sparkle,
            color: AppColors.lilac,
            onColor: AppColors.mauve,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kHeading.copyWith(fontSize: 20, letterSpacing: -0.4)),
                const SizedBox(height: 4),
                Text(detail, style: kSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final Lateness lateness;
  const _AdviceCard({required this.lateness});

  String get _text => switch (lateness) {
        Lateness.none => '',
        Lateness.withinMargin =>
          'Masih dalam rentang wajar. Siklus bisa maju atau mundur beberapa hari.',
        Lateness.late =>
          'Haid belum datang melewati rentang perkiraan. Stres, kurang tidur, atau perubahan '
              'berat badan bisa memengaruhi siklus.',
        Lateness.veryLate =>
          'Sudah seminggu atau lebih dari perkiraan. Bila ada kemungkinan hamil, pertimbangkan '
              'tes kehamilan. Bila terus terlambat, konsultasikan ke dokter.',
        Lateness.seeDoctor =>
          'Sudah 3 bulan atau lebih sejak haid terakhir yang tercatat. Bila haid sebenarnya sudah '
              'datang, catat tanggalnya. Bila belum, sebaiknya periksa ke dokter.',
      };

  @override
  Widget build(BuildContext context) => PinkCard(
        color: AppColors.petal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(PhosphorIconsRegular.info, color: AppColors.rose),
            const SizedBox(width: 12),
            Expanded(child: Text(_text, style: const TextStyle(height: 1.4))),
          ],
        ),
      );
}

class _LogActions extends ConsumerWidget {
  const _LogActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(periodLogsProvider);
    final today = ref.watch(todayProvider);
    final last = logs.isEmpty ? null : logs.last;
    final endable = (last != null &&
            last.end == null &&
            !today.isBefore(dateOnly(last.start)) &&
            today.difference(dateOnly(last.start)).inDays < 10)
        ? last
        : null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => logPeriodStart(context, ref, today),
            icon: const Icon(PhosphorIconsFill.drop),
            label: const Text('Haid mulai hari ini'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => pickAndLogPeriodStart(context, ref),
                child: const Text('Pilih tanggal lain'),
              ),
            ),
            if (endable != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(periodLogsProvider.notifier).setEnd(endable.start, today),
                  child: const Text('Haid selesai'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TodayNoteCard extends ConsumerWidget {
  const _TodayNoteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final note = ref.watch(notesProvider)[today];
    return PinkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: AppColors.petal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.notepad, color: AppColors.rose, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Catatan hari ini', style: kHeading.copyWith(fontSize: 18, letterSpacing: -0.3)),
            ],
          ),
          const SizedBox(height: 12),
          if (note == null)
            const Text('Belum ada catatan. Gejala atau suasana hatimu hari ini?', style: kSmall)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (note.flow != null) TagChip('Aliran ${kFlowLabels[note.flow]!.toLowerCase()}'),
                for (final s in note.symptoms) TagChip(symptomLabel(s)),
                for (final m in note.moods) TagChip(moodLabel(m)),
                if (note.note.isNotEmpty) const TagChip('📝 ada catatan'),
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openLog(context, today),
              icon: const Icon(PhosphorIconsRegular.plus),
              label: Text(note == null ? 'Catat gejala & mood' : 'Ubah catatan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoveLetterEnvelopeCard extends ConsumerWidget {
  const _LoveLetterEnvelopeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(activeLoveNoteProvider);
    if (note == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => showLoveLetterModal(context, ref, note),
        borderRadius: BorderRadius.circular(28),
        child: PinkCard(
          color: AppColors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: note.isRead
                        ? [AppColors.blush, AppColors.petal]
                        : [AppColors.petal, AppColors.petalGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowDiffuse,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  note.isRead
                      ? PhosphorIconsFill.envelope
                      : PhosphorIconsFill.envelopeOpen,
                  color: AppColors.rose,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Surat Cinta 💌',
                          style: kHeading.copyWith(fontSize: 16, letterSpacing: -0.3),
                        ),
                        const SizedBox(width: 6),
                        if (!note.isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowDiffuse,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'BARU',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      note.isRead
                          ? 'Dari ${note.sender}: Buka untuk membaca pesan manis ini 🎀'
                          : 'Ada pesan perhatian dari ${note.sender} untukmu hari ini 💕',
                      style: kSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.reaction != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reaksi kamu: ${note.reaction}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.rose,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: AppColors.mauveSoft,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
