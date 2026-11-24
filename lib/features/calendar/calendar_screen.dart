// lib/features/calendar/calendar_screen.dart
// Kalender bulanan berwarna per fase. Warna dari phaseStyle(); data dari dayViewFor().
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../application/providers.dart';
import '../../core/formatters.dart';
import '../../core/note_labels.dart';
import '../../core/phase_style.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/cycle_engine.dart';
import '../../domain/day_note.dart';
import '../../domain/day_view.dart';
import '../home/log_actions.dart';
import '../log/log_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(cycleEngineProvider);
    final logs = ref.watch(periodLogsProvider);
    final prediction = ref.watch(predictionProvider);
    final today = ref.watch(todayProvider);
    final notes = ref.watch(notesProvider);

    DayView? viewOf(DateTime d) => dayViewFor(
          d,
          engine: engine,
          logs: logs,
          prediction: prediction,
          today: today,
        );

    Widget cell(DateTime day, {bool isSelected = false}) {
      final v = viewOf(day);
      final isToday = isSameDay(day, today);
      final hasNote = notes.containsKey(dateOnly(day));
      final st = v == null ? null : phaseStyle(v.phase);
      final predictedPeriod = v != null && v.phase == CyclePhase.menstrual && !v.logged;
      final Color? bg = st == null ? null : (predictedPeriod ? AppColors.petal : st.color);
      final Color fg = (st == null || predictedPeriod) ? AppColors.mauve : st.onColor;
      return Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.mauve, width: 2)
              : isToday
                  ? Border.all(color: AppColors.rose, width: 2)
                  : predictedPeriod
                      ? Border.all(color: AppColors.rose, width: 1.5)
                      : null,
          boxShadow: (st != null && !predictedPeriod) || isSelected
              ? [
                  BoxShadow(
                    color: (st?.color ?? AppColors.rose).withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: fg,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (v != null && v.phase == CyclePhase.ovulation)
              const Positioned(
                top: 1,
                right: 3,
                child: Icon(PhosphorIconsFill.sparkle, size: 10, color: AppColors.mauve),
              ),
            if (v != null && v.isFertile && v.phase == CyclePhase.menstrual)
              Positioned(
                bottom: 3,
                left: 8,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.lilac,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mauve, width: 0.8),
                  ),
                ),
              ),
            if (hasNote)
              Positioned(
                bottom: 3,
                right: 8,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppColors.mauve, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const BowHeader(title: 'Kalender', subtitle: 'Warna menunjukkan fase siklusmu'),
        const SizedBox(height: 16),
        PinkCard(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: TableCalendar<void>(
            locale: 'id_ID',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableGestures: AvailableGestures.horizontalSwipe,
            rowHeight: 52,
            selectedDayPredicate: (d) => _selected != null && isSameDay(_selected, d),
            onDaySelected: (selected, focused) {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
              _showDaySheet(selected, viewOf(selected), logs, today);
            },
            onPageChanged: (focused) => _focused = focused,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: kHeading.copyWith(fontSize: 18),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.petal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.rose, size: 16),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.petal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.caretRight, color: AppColors.rose, size: 16),
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppColors.mauveSoft,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: AppColors.rose,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focused) => cell(day),
              todayBuilder: (context, day, focused) => cell(day),
              selectedBuilder: (context, day, focused) => cell(day, isSelected: true),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _Legend(),
      ],
    );
  }

  void _showDaySheet(DateTime day, DayView? v, List<PeriodLog> logs, DateTime today) {
    final d = dateOnly(day);
    final isStart = logs.any((l) => dateOnly(l.start) == d);
    final DayNote? note = ref.read(notesProvider)[d];
    final canEdit = !d.isAfter(today);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final st = v == null ? null : phaseStyle(v.phase);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmtFull(d), style: kHeading.copyWith(fontSize: 22)),
              const SizedBox(height: 12),
              if (v == null || st == null)
                const Text('Belum ada data atau prediksi untuk tanggal ini.', style: kSmall)
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PhaseChip(
                      label: st.label,
                      icon: st.icon,
                      color: st.color,
                      onColor: st.onColor,
                    ),
                    Text(
                      '${v.cycleDay != null ? 'Hari siklus ke-${v.cycleDay} · ' : ''}'
                      '${v.logged ? 'tercatat' : 'prediksi'}',
                      style: kSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(st.hint, style: kSmall),
                if (v.isFertile && v.phase == CyclePhase.menstrual) ...[
                  const SizedBox(height: 4),
                  const Text('Hari ini juga masuk perkiraan masa subur.', style: kSmall),
                ],
              ],
              if (note != null) ...[
                const SizedBox(height: 14),
                Text('Catatanmu', style: kHeading.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (note.flow != null) TagChip('Aliran ${kFlowLabels[note.flow]!.toLowerCase()}'),
                    for (final s in note.symptoms) TagChip(symptomLabel(s)),
                    for (final m in note.moods) TagChip(moodLabel(m)),
                  ],
                ),
                if (note.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(note.note, style: const TextStyle(height: 1.4)),
                ],
              ],
              if (canEdit) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: isStart
                      ? OutlinedButton(
                          onPressed: () {
                            ref.read(periodLogsProvider.notifier).remove(d);
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Hapus catatan haid ini'),
                        )
                      : FilledButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            logPeriodStart(context, ref, d);
                          },
                          child: const Text('Tandai haid mulai di sini'),
                        ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      openLog(context, d);
                    },
                    icon: const Icon(PhosphorIconsRegular.notePencil),
                    label: Text(note == null ? 'Catat gejala & mood' : 'Ubah catatan'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => PinkCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in CyclePhase.values)
                  PhaseChip(
                    label: phaseStyle(p).label,
                    icon: phaseStyle(p).icon,
                    color: phaseStyle(p).color,
                    onColor: phaseStyle(p).onColor,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Lingkaran penuh = haid tercatat. Lingkaran terang berbingkai = prediksi haid. '
              'Titik gelap = ada catatan harian. Ketuk tanggal untuk detail.',
              style: kSmall,
            ),
          ],
        ),
      );
}
