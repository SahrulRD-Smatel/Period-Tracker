// lib/features/home/home_screen.dart
// Beranda gaya Cyra yang disempurnakan: sapaan + strip mingguan + cincin siklus + tombol bulat + rail kartu pastel.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/formatters.dart';
import '../../core/note_labels.dart';
import '../../core/phase_style.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/cycle_engine.dart';
import '../../domain/cycle_sync.dart';
import '../../domain/home_summary.dart';
import '../log/log_screen.dart';
import 'cycle_ring.dart';
import 'log_actions.dart';
import 'love_letter_dialog.dart';

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
                begin: const Offset(0.94, 0.94),
                duration: 450.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 350.ms),
          const SizedBox(height: 14),
          const _LogActions()
              .animate(delay: 70.ms)
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
          if (s.lateness != Lateness.none) ...[
            const SizedBox(height: 14),
            _AdviceCard(lateness: s.lateness)
                .animate(delay: 110.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.05, curve: Curves.easeOut),
          ],
          const SizedBox(height: 16),
          _CardRail(summary: s)
              .animate(delay: 140.ms)
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        _HomeHeader(today: today)
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: -0.04, curve: Curves.easeOut),
        const SizedBox(height: 10),
        _WeekStrip(today: today),
        const SizedBox(height: 12),
        body,
        const SizedBox(height: 18),
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
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: 14),
                Text('Selamat datang', style: kHeading.copyWith(fontSize: 26, letterSpacing: -0.6)),
                const SizedBox(height: 8),
                const Text(
                  'Mulai dengan mencatat hari pertama haid terakhirmu. '
                  'Makin banyak data, makin akurat perkiraannya.',
                  textAlign: TextAlign.center,
                  style: kSmall,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => pickAndLogPeriodStart(context, ref),
                    child: const Text('Catat haid terakhir'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _LoveLetterEnvelopeCard(),
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

  ({String label, String big, String pill}) _center() {
    final s = summary;
    final d = s.daysUntilPeriod;
    final today = prediction.current.periodStart.add(Duration(days: s.cycleDay - 1));
    final toOv = s.ovulation?.difference(today).inDays;

    if (d < 0) {
      return (label: 'Haid terlambat', big: '${-d} hari', pill: 'Catat bila sudah datang');
    }
    if (s.phase == CyclePhase.menstrual) {
      final ovHint = (toOv != null && toOv >= 0) ? 'Ovulasi ±$toOv hari lagi' : '$d hari lagi ke haid';
      return (
        label: 'Hari haid ke-',
        big: '${s.cycleDay}',
        pill: ovHint,
      );
    }
    if (toOv != null && toOv >= 0) {
      return (
        label: 'Ovulasi dalam',
        big: toOv == 0 ? 'Hari ini' : '$toOv hari',
        pill: d == 0 ? 'Haid hari ini' : '$d hari lagi ke haid',
      );
    }
    return (
      label: 'Haid dalam',
      big: d == 0 ? 'Hari ini' : '$d hari',
      pill: 'Hari ke-${s.cycleDay}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = phaseStyle(summary.phase);
    final c = _center();
    return PinkCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          CycleRing(
            size: 204,
            dayColors: _ringColors(prediction.current),
            currentIndex: summary.cycleDay - 1,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.label,
                  style: kSmall.copyWith(color: AppColors.mauve, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  c.big,
                  style: kHeading.copyWith(
                    fontSize: 34,
                    height: 1.05,
                    letterSpacing: -1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.mauveSoft),
                  ),
                  child: Text(c.pill, style: kSmall.copyWith(fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PhaseChip(label: st.label, icon: st.icon, color: st.color, onColor: st.onColor),
          const SizedBox(height: 6),
          Text(st.hint, textAlign: TextAlign.center, style: kSmall),
        ],
      ),
    );
  }
}

/// Kartu pastel ala Cyra: pill judul putih + isi.
class _PastelCard extends StatelessWidget {
  final Color color;
  final String tag;
  final Widget child;
  final VoidCallback? onTap;
  const _PastelCard({required this.color, required this.tag, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      tag,
                      style: kSmall.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mauve,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}

/// Rail kartu yang bisa digeser: surat cinta (bila ada), suasana hati, fase, masa subur, haid berikutnya.
class _CardRail extends ConsumerWidget {
  final HomeSummary summary;
  const _CardRail({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLetter = ref.watch(activeLoveNoteProvider) != null;
    final cards = <Widget>[
      if (hasLetter) const _LoveLetterEnvelopeCard(),
      const _FeelCard(),
      _PhaseCard(summary: summary),
      _FertileCard(summary: summary),
      _CountdownCard(summary: summary),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth * 0.78;
        return SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: w, child: cards[i]),
          ),
        );
      },
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final HomeSummary summary;
  const _PhaseCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final st = phaseStyle(summary.phase);
    return _PastelCard(
      color: AppColors.petal,
      tag: st.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari ke-${summary.cycleDay}',
            style: kHeading.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          Text(st.hint, style: kSmall.copyWith(color: AppColors.mauve)),
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
  Widget build(BuildContext context) => _PastelCard(
        color: AppColors.honey.withValues(alpha: 0.55),
        tag: summary.daysUntilPeriod >= 0 ? 'Haid berikutnya' : 'Haid belum datang',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _big,
              style: kHeading.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            ),
            const SizedBox(height: 6),
            Text(
              'Rentang perkiraan: ${fmtRange(summary.periodEarliest, summary.periodLatest)}',
              style: kSmall.copyWith(color: AppColors.mauve, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Keyakinan: $_confidence', style: kSmall.copyWith(color: AppColors.mauve)),
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
    return _PastelCard(
      color: AppColors.lilac,
      tag: 'Masa subur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: kHeading.copyWith(fontSize: 20, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text(detail, style: kSmall.copyWith(color: AppColors.mauve)),
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
    final endable = activeOpenPeriod(logs, today);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CircleAction(
            icon: PhosphorIconsFill.drop,
            label: 'Haid mulai',
            filled: true,
            onTap: () => logPeriodStart(context, ref, today),
          ),
        ),
        Expanded(
          child: _CircleAction(
            icon: PhosphorIconsRegular.calendarDots,
            label: 'Pilih tanggal',
            onTap: () => pickAndLogPeriodStart(context, ref),
          ),
        ),
        if (endable != null)
          Expanded(
            child: _CircleAction(
              icon: PhosphorIconsFill.checkCircle,
              label: 'Haid selesai',
              onTap: () async {
                await ref.read(periodLogsProvider.notifier).setEnd(endable.start, today);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tercatat: haid selesai ${fmtDayMonth(today)} 🌸'),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: _CircleAction(
            icon: PhosphorIconsRegular.plus,
            label: 'Tambah gejala',
            onTap: () => openLog(context, today),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.rose : AppColors.white,
                    border: filled ? null : Border.all(color: AppColors.track, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: AppColors.shadowDiffuse, blurRadius: 12, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Icon(icon, size: 22, color: filled ? AppColors.white : AppColors.mauve),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: kSmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mauve,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _FeelCard extends ConsumerWidget {
  const _FeelCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final note = ref.watch(notesProvider)[today];
    return _PastelCard(
      color: AppColors.peach,
      tag: 'Bagaimana perasaanmu?',
      onTap: () => openLog(context, today),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note == null)
            Text(
              'Belum ada catatan. Gejala atau suasana hatimu hari ini?',
              style: kSmall.copyWith(color: AppColors.mauve),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (note.ovulationPositive) const TagChip('✨ Ovulasi (+)'),
                if (note.flow != null) TagChip('Aliran ${kFlowLabels[note.flow]!.toLowerCase()}'),
                for (final s in note.symptoms) TagChip(symptomLabel(s)),
                for (final m in note.moods) TagChip(moodLabel(m)),
                if (note.note.isNotEmpty) const TagChip('📝 ada catatan'),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.plus, size: 16, color: AppColors.mauve),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note == null ? 'Catat gejala & mood' : 'Ubah catatan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.mauve),
                ),
              ),
            ],
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
    return _PastelCard(
      color: AppColors.ribbon.withValues(alpha: 0.6),
      tag: 'Surat Cinta 💌',
      onTap: () => showLoveLetterModal(context, ref, note),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!note.isRead)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
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
            ),
          Text(
            note.isRead
                ? 'Dari ${note.sender}: Buka untuk membaca pesan manis ini 🎀'
                : 'Ada pesan perhatian dari ${note.sender} untukmu hari ini 💕',
            style: kSmall.copyWith(color: AppColors.mauve),
          ),
          if (note.reaction != null) ...[
            const SizedBox(height: 6),
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
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final DateTime today;
  const _HomeHeader({required this.today});

  @override
  Widget build(BuildContext context) {
    final hr = DateTime.now().hour;
    final sal = hr < 11 ? 'pagi' : hr < 15 ? 'siang' : hr < 18 ? 'sore' : 'malam';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hai, selamat $sal',
          style: kSmall.copyWith(color: AppColors.whiteSoft, fontWeight: FontWeight.w500),
        ),
        Text(
          'Siklusku',
          style: kHeading.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.white,
          ),
        ),
        Text(fmtFull(today), style: kSmall.copyWith(color: AppColors.whiteSoft)),
      ],
    );
  }
}

/// Strip 7 hari (hari ini di tengah). Ketuk hari yang sudah lewat / hari ini untuk membuka catatan.
class _WeekStrip extends StatelessWidget {
  final DateTime today;
  const _WeekStrip({required this.today});

  static const _w = ['S', 'S', 'R', 'K', 'J', 'S', 'M']; // Senin..Minggu

  Widget _chip(BuildContext context, DateTime d, bool sel) {
    final enabled = !d.isAfter(today);
    return Semantics(
      button: enabled,
      label: 'Catatan ${fmtDayMonth(d)}',
      child: InkWell(
        onTap: enabled ? () => openLog(context, d) : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: sel ? AppColors.primaryGradient : null,
            color: sel ? null : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: AppColors.shadowContact, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Text(
                _w[d.weekday - 1],
                style: kSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: sel ? AppColors.white : AppColors.mauveSoft,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${d.day}'.padLeft(2, '0'),
                style: kHeading.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: sel ? AppColors.white : AppColors.mauve,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var k = -3; k <= 3; k++) ...[
            if (k > -3) const SizedBox(width: 8),
            Expanded(child: _chip(context, today.add(Duration(days: k)), k == 0)),
          ],
        ],
      );
}
