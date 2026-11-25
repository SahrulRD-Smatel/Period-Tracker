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
import '../../domain/cycle_sync.dart';
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
  late DateTime _focused;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _focused = ref.read(todayProvider);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(cycleEngineProvider);
    final logs = ref.watch(periodLogsProvider);
    final prediction = ref.watch(predictionProvider);
    final today = ref.watch(todayProvider);
    final notes = ref.watch(notesProvider);
    final defPeriodLen = ref.watch(settingsProvider).periodLength;

    DayView? viewOf(DateTime d) => dayViewFor(
          d,
          engine: engine,
          logs: logs,
          prediction: prediction,
          today: today,
        );

    Widget cell(DateTime day, {bool isSelected = false}) {
      final d = dateOnly(day);
      final v = viewOf(day);
      final isToday = isSameDay(day, today);
      final note = notes[d];
      final hasNote = note != null;
      final st = v == null ? null : phaseStyle(v.phase);
      final predictedPeriod = v != null && v.phase == CyclePhase.menstrual && !v.logged;
      final Color? bg = st == null ? null : (predictedPeriod ? AppColors.petal : st.color);
      final Color fg = (st == null || predictedPeriod) ? AppColors.mauve : st.onColor;
      return Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? null : bg,
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : isToday
                  ? Border.all(color: AppColors.mauve, width: 1.8)
                  : predictedPeriod
                      ? Border.all(color: AppColors.rose, width: 1.5)
                      : null,
          boxShadow: isSelected
              ? const [BoxShadow(color: AppColors.shadowDiffuse, blurRadius: 10, offset: Offset(0, 4))]
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
                color: isSelected ? AppColors.white : fg,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if ((v != null && v.phase == CyclePhase.ovulation) || (note?.ovulationPositive ?? false))
              const Positioned(
                top: 2,
                right: 3,
                child: Icon(PhosphorIconsFill.sparkle, size: 9, color: AppColors.mauve),
              ),
            if (v != null && v.isFertile && v.phase == CyclePhase.menstrual)
              Positioned(
                bottom: 2,
                left: 8,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.lilac,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mauve, width: 0.8),
                  ),
                ),
              ),
            if (hasNote)
              Positioned(
                bottom: 2,
                right: 8,
                child: Container(
                  width: 5,
                  height: 5,
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
              _showDaySheet(selected, viewOf(selected), logs, today, defPeriodLen);
            },
            onPageChanged: (focused) => _focused = focused,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: kHeading.copyWith(fontSize: 18),
              leftChevronIcon: const _Chevron(PhosphorIconsRegular.caretLeft),
              rightChevronIcon: const _Chevron(PhosphorIconsRegular.caretRight),
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

  void _showDaySheet(
    DateTime day,
    DayView? v,
    List<PeriodLog> logs,
    DateTime today,
    int defaultPeriodLen,
  ) {
    final d = dateOnly(day);
    final isStart = logs.any((l) => dateOnly(l.start) == d);
    final sameEpisode = findSameEpisodeLog(logs, d);
    final containing = logContainingDate(logs, d, defaultPeriodLen: defaultPeriodLen);
    final openPeriod = activeOpenPeriod(logs, d);
    final DayNote? note = ref.read(notesProvider)[d];
    final canEdit = !d.isAfter(today);

    final targetForEnd = (containing != null && d.isAfter(dateOnly(containing.start)))
        ? containing
        : (openPeriod != null && d.isAfter(dateOnly(openPeriod.start)) ? openPeriod : null);

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
                if (containing?.end != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Durasi haid tercatat: ${fmtRange(containing!.start, containing.end!)}.',
                    style: kSmall,
                  ),
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
                    if (note.ovulationPositive) const TagChip('✨ Tes ovulasi positif'),
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
                if (targetForEnd != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        ref.read(periodLogsProvider.notifier).setEnd(targetForEnd.start, d);
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(PhosphorIconsFill.checkCircle),
                      label: Text(
                        targetForEnd.end == d
                            ? 'Haid selesai tercatat di tanggal ini'
                            : 'Tandai haid selesai di tanggal ini',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (containing != null && containing.end != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(periodLogsProvider.notifier).setEnd(containing.start, null);
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Reset tanggal selesai haid'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
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
                      : OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            logPeriodStart(
                              context,
                              ref,
                              d,
                              confirmForwardShift:
                                  sameEpisode != null && d.isAfter(sameEpisode.start),
                            );
                          },
                          child: Text(
                            sameEpisode == null
                                ? 'Tandai haid mulai di sini'
                                : d.isBefore(sameEpisode.start)
                                    ? 'Jadikan hari pertama haid'
                                    : 'Geser hari pertama haid ke sini',
                          ),
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
              'Kotak penuh = haid tercatat. Kotak terang berbingkai = prediksi haid. '
              'Titik gelap = ada catatan harian. Ketuk tanggal untuk detail atau atur haid selesai.',
              style: kSmall,
            ),
          ],
        ),
      );
}

class _Chevron extends StatelessWidget {
  final IconData icon;
  const _Chevron(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.shadowContact, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: AppColors.mauve, size: 16),
      );
}
