// lib/features/stats/stats_screen.dart
// Statistik: ringkasan, diagram panjang siklus, tepat waktu/cepat/terlambat, riwayat.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/formatters.dart';
import '../../core/note_labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/cycle_engine.dart';
import '../../domain/stats.dart';
import 'cycle_bars.dart';

String _num(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const BowHeader(title: 'Statistik', subtitle: 'Pola siklusmu dari waktu ke waktu')
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: -0.04, curve: Curves.easeOut),
        const SizedBox(height: 16),
        if (!stats.hasData)
          const _EmptyStats()
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut)
        else ...[
          _SummaryGrid(stats: stats)
              .animate(delay: 60.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
          const SizedBox(height: 14),
          _ChartCard(stats: stats)
              .animate(delay: 120.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
          const SizedBox(height: 14),
          if (stats.hasOutcomes)
            _OutcomeCard(stats: stats)
                .animate(delay: 180.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.05, curve: Curves.easeOut)
          else
            const _NeedMoreData()
                .animate(delay: 180.ms)
                .fadeIn(duration: 350.ms),
          const SizedBox(height: 14),
          _HistoryCard(stats: stats)
              .animate(delay: 240.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
        ],
      ],
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) => PinkCard(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.petal,
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.chartLineUp, color: AppColors.rose, size: 36),
            ),
            const SizedBox(height: 8),
            Text('Belum ada statistik', style: kHeading.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            const Text(
              'Catat minimal 2 haid untuk melihat panjang siklus pertamamu.',
              textAlign: TextAlign.center,
              style: kSmall,
            ),
          ],
        ),
      );
}

class _NeedMoreData extends StatelessWidget {
  const _NeedMoreData();

  @override
  Widget build(BuildContext context) => const PinkCard(
        color: AppColors.petal,
        child: Text(
          'Catat minimal 4 haid (3 siklus) untuk melihat seberapa teratur siklusmu.',
          style: TextStyle(height: 1.4),
        ),
      );
}

class _SummaryGrid extends StatelessWidget {
  final CycleStats stats;
  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final avg = stats.avgCycle == null ? '–' : '${_num(stats.avgCycle!)} hari';
    final range = stats.minCycle == null ? '–' : '${stats.minCycle}–${stats.maxCycle} hari';
    final period = stats.avgPeriod == null ? '–' : '${_num(stats.avgPeriod!)} hari';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: PhosphorIconsRegular.arrowsClockwise,
                label: 'Rata-rata siklus',
                value: avg,
                tone: AppColors.petal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: PhosphorIconsRegular.arrowsLeftRight,
                label: 'Rentang siklus',
                value: range,
                tone: AppColors.peach,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: PhosphorIconsFill.drop,
                label: 'Lama haid',
                value: period,
                tone: AppColors.lilac,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: PhosphorIconsRegular.chartLineUp,
                label: 'Keteraturan',
                value: regularityLabel(stats.regularity),
                tone: AppColors.honey.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final CycleStats stats;
  const _ChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final shown = stats.cycles.length > 12
        ? stats.cycles.sublist(stats.cycles.length - 12)
        : stats.cycles;
    final labels = [for (final c in shown) DateFormat('MMM', 'id_ID').format(c.start)];
    return PinkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Panjang siklus (hari)', style: kHeading.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: CycleBarsPainter(
                cycles: shown,
                labels: labels,
                avg: stats.avgCycle ?? 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Area abu = rentang normal 21–35 hari. Garis putus-putus = rata-rata. '
            'Label bulan = bulan siklus dimulai.',
            style: kSmall,
          ),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  final CycleStats stats;
  const _OutcomeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.onTime + stats.early + stats.late;
    final items = <(CycleOutcome, int)>[
      (CycleOutcome.onTime, stats.onTime),
      (CycleOutcome.early, stats.early),
      (CycleOutcome.late, stats.late),
    ];
    return PinkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tepat waktu, cepat, atau terlambat', style: kHeading.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  for (final it in items)
                    if (it.$2 > 0)
                      Expanded(
                        flex: it.$2,
                        child: Container(color: outcomeStyle(it.$1).color),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: outcomeStyle(it.$1).color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(outcomeStyle(it.$1).label)),
                  Text(
                    '${it.$2} siklus · ${total == 0 ? 0 : (it.$2 * 100 / total).round()}%',
                    style: kSmall,
                  ),
                ],
              ),
            ),
          const Text(
            'Dibandingkan dengan median siklusmu, toleransi ±2 hari.',
            style: kSmall,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CycleStats stats;
  const _HistoryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = stats.cycles.reversed.take(20).toList();
    return PinkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat siklus', style: kHeading.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 18, color: AppColors.petal),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mulai ${fmtDayMonth(items[i].start)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${items[i].length} hari'
                        '${items[i].periodLength != null ? ' · haid ${items[i].periodLength} hari' : ''}',
                        style: kSmall,
                      ),
                    ],
                  ),
                ),
                if (items[i].outcome != null)
                  PhaseChip(
                    label: outcomeStyle(items[i].outcome!).label,
                    icon: PhosphorIconsFill.circle,
                    color: outcomeStyle(items[i].outcome!).color,
                    onColor: outcomeStyle(items[i].outcome!).onColor,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
