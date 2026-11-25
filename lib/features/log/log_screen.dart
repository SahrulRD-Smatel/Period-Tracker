// lib/features/log/log_screen.dart
// Catat aliran haid (otomatis terhubung ke riwayat siklus), tes ovulasi (LH/BBT),
// gejala, suasana hati, dan catatan harian.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/app_scaffold.dart';
import '../../core/dialogs.dart';
import '../../core/formatters.dart';
import '../../core/note_labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/cycle_engine.dart';
import '../../domain/cycle_sync.dart';
import '../../domain/day_note.dart';

Future<void> openLog(BuildContext context, DateTime date) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LogScreen(date: date)));

class LogScreen extends ConsumerStatefulWidget {
  final DateTime date;
  const LogScreen({super.key, required this.date});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  late DateTime _date;
  FlowLevel? _flow;
  bool _ovulationPositive = false;
  Set<String> _symptoms = {};
  Set<String> _moods = {};
  final _note = TextEditingController();
  bool _existing = false;
  bool _markAsPeriodStart = false;
  bool _markAsPeriodEnd = false;

  @override
  void initState() {
    super.initState();
    _date = dateOnly(widget.date);
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _load() {
    final n = ref.read(notesProvider)[_date];
    _existing = n != null;
    _flow = n?.flow;
    _ovulationPositive = n?.ovulationPositive ?? false;
    _symptoms = {...?n?.symptoms};
    _moods = {...?n?.moods};
    _note.text = n?.note ?? '';
    _markAsPeriodStart = false;
    _markAsPeriodEnd = false;
  }

  void _selectFlow(FlowLevel? level) {
    final next = _flow == level ? null : level;
    final logs = ref.read(periodLogsProvider);
    final defPeriodLen = ref.read(settingsProvider).periodLength;
    setState(() {
      _flow = next;
      _markAsPeriodStart = shouldAutoStartPeriod(
        logs,
        _date,
        next,
        defaultPeriodLen: defPeriodLen,
      );
      if (next == null) _markAsPeriodEnd = false;
    });
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _date = dateOnly(picked);
      _load();
    });
  }

  Future<void> _save() async {
    final n = DayNote(
      date: _date,
      flow: _flow,
      ovulationPositive: _ovulationPositive,
      symptoms: {..._symptoms},
      moods: {..._moods},
      note: _note.text.trim(),
    );
    await ref.read(notesProvider.notifier).save(n);

    var cycleChanged = false;
    final logs = ref.read(periodLogsProvider);
    final openPeriod = activeOpenPeriod(logs, _date);

    if (_markAsPeriodStart && _flow != null) {
      final added = await ref.read(periodLogsProvider.notifier).addStart(_date);
      cycleChanged = added;
    } else if (_markAsPeriodEnd && openPeriod != null && _date.isAfter(dateOnly(openPeriod.start))) {
      await ref.read(periodLogsProvider.notifier).setEnd(openPeriod.start, _date);
      cycleChanged = true;
    }

    if (!mounted) return;
    if (cycleChanged || _ovulationPositive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cycleChanged
                ? 'Catatan & tanggal haid disimpan. Kalender & prediksi diperbarui 🎀'
                : 'Catatan & tes ovulasi disimpan. Perkiraan haid disesuaikan ✨',
          ),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus catatan?',
      message: 'Catatan tanggal ${fmtDayMonth(_date)} akan dihapus.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(notesProvider.notifier).remove(_date);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggle(Set<String> set, String id) {
    setState(() {
      if (set.contains(id)) {
        set.remove(id);
      } else {
        set.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(periodLogsProvider);
    final defPeriodLen = ref.watch(settingsProvider).periodLength;
    final containing = logContainingDate(logs, _date, defaultPeriodLen: defPeriodLen);
    final openPeriod = activeOpenPeriod(logs, _date);
    final canStartPeriod = _flow != null &&
        containing == null &&
        shouldAutoStartPeriod(logs, _date, _flow, defaultPeriodLen: defPeriodLen);
    final canEndPeriod =
        _flow != null && openPeriod != null && _date.isAfter(dateOnly(openPeriod.start));

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.rose),
                ),
                Text('Catat hari ini', style: kHeading.copyWith(fontSize: 24)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: PinkCard(
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.calendarDots, color: AppColors.rose),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(fmtFull(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.mist),
                      ],
                    ),
                  ),
                ),
                const SectionTitle('Aliran haid'),
                PinkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in kFlowLabels.entries)
                            PinkChoiceChip(
                              label: e.value,
                              selected: _flow == e.key,
                              onTap: () => _selectFlow(e.key),
                            ),
                        ],
                      ),
                      if (canStartPeriod) ...[
                        const Divider(height: 24, color: AppColors.petal),
                        SwitchRow(
                          title: 'Tandai hari pertama haid',
                          subtitle: 'Otomatis perbarui cincin siklus & kalender prediksi',
                          value: _markAsPeriodStart,
                          onChanged: (v) => setState(() {
                            _markAsPeriodStart = v;
                            if (v) _markAsPeriodEnd = false;
                          }),
                        ),
                      ] else if (canEndPeriod) ...[
                        const Divider(height: 24, color: AppColors.petal),
                        SwitchRow(
                          title: 'Tandai haid selesai di tanggal ini',
                          subtitle: 'Haid dimulai ${fmtDayMonth(openPeriod.start)}',
                          value: _markAsPeriodEnd,
                          onChanged: (v) => setState(() => _markAsPeriodEnd = v),
                        ),
                      ] else if (containing != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Masuk dalam haid tercatat (${fmtDayMonth(containing.start)}).',
                          style: kSmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SectionTitle('Tes ovulasi (LH / BBT)'),
                PinkCard(
                  child: SwitchRow(
                    title: 'Hasil tes ovulasi positif (+)',
                    subtitle: 'Membantu prediksi tanggal haid berikutnya jauh lebih akurat',
                    value: _ovulationPositive,
                    onChanged: (v) => setState(() => _ovulationPositive = v),
                  ),
                ),
                const SectionTitle('Gejala'),
                PinkCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in kSymptoms.entries)
                        PinkChoiceChip(
                          label: e.value,
                          selected: _symptoms.contains(e.key),
                          onTap: () => _toggle(_symptoms, e.key),
                        ),
                    ],
                  ),
                ),
                const SectionTitle('Suasana hati'),
                PinkCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in kMoods.entries)
                        PinkChoiceChip(
                          label: e.value,
                          selected: _moods.contains(e.key),
                          onTap: () => _toggle(_moods, e.key),
                        ),
                    ],
                  ),
                ),
                const SectionTitle('Catatan'),
                PinkCard(
                  child: TextField(
                    controller: _note,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Tulis apa pun yang ingin kamu ingat…',
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
                ),
                const SizedBox(height: 4),
                const Text(
                  'Catatan ini hanya tersimpan di perangkatmu dan tidak pernah dibagikan ke pasangan.',
                  textAlign: TextAlign.center,
                  style: kSmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                if (_existing) ...[
                  Expanded(
                    child: OutlinedButton(onPressed: _delete, child: const Text('Hapus')),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(onPressed: _save, child: const Text('Simpan')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
