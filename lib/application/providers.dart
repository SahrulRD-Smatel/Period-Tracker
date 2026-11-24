// lib/application/providers.dart
// Alur data: periodLogs/settings -> engine -> prediction -> homeSummary / stats / dayView -> UI.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cycle_repository.dart';
import '../data/local_store.dart';
import '../data/partner_repository.dart';
import '../domain/app_settings.dart';
import '../domain/cycle_engine.dart';
import '../domain/day_note.dart';
import '../domain/home_summary.dart';
import '../domain/love_notes.dart';
import '../domain/partner_models.dart';
import '../domain/stats.dart';

// ---------- infrastruktur ----------
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPrefsProvider di main() / test'),
);

final cycleRepositoryProvider = Provider<CycleRepository>(
  (ref) => PrefsCycleRepository(ref.watch(sharedPrefsProvider)),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => PrefsSettingsRepository(ref.watch(sharedPrefsProvider)),
);
final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => PrefsNotesRepository(ref.watch(sharedPrefsProvider)),
);
final loveNotesRepositoryProvider = Provider<LoveNotesRepository>(
  (ref) => PrefsLoveNotesRepository(ref.watch(sharedPrefsProvider)),
);
// Ganti ke implementasi Supabase saat backend siap.
final partnerRepositoryProvider = Provider<PartnerRepository>((ref) => DemoPartnerRepository());

// ---------- setelan ----------
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings s) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }

  Future<void> replace(AppSettings s) => update((_) => s);
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Engine mengikuti setelan (panjang siklus/haid/luteal default).
final cycleEngineProvider = Provider<CycleEngine>(
  (ref) => CycleEngine(ref.watch(settingsProvider).toCycleSettings()),
);

/// Tanggal "hari ini" (UTC, tanpa jam). Di-invalidate saat aplikasi kembali ke foreground.
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

// ---------- riwayat haid ----------
class PeriodLogsNotifier extends Notifier<List<PeriodLog>> {
  @override
  List<PeriodLog> build() =>
      [...ref.watch(cycleRepositoryProvider).load()]..sort((a, b) => a.start.compareTo(b.start));

  Future<void> _commit(List<PeriodLog> logs) async {
    logs.sort((a, b) => a.start.compareTo(b.start));
    state = List.unmodifiable(logs);
    await ref.read(cycleRepositoryProvider).save(state);
  }

  /// false bila tanggal itu sudah tercatat.
  Future<bool> addStart(DateTime date) async {
    final d = dateOnly(date);
    if (state.any((l) => dateOnly(l.start) == d)) return false;
    await _commit([...state, PeriodLog(start: d)]);
    return true;
  }

  Future<void> setEnd(DateTime start, DateTime end) async {
    final s = dateOnly(start), e = dateOnly(end);
    if (e.isBefore(s)) return;
    await _commit([
      for (final l in state)
        dateOnly(l.start) == s ? PeriodLog(start: l.start, end: e) : l,
    ]);
  }

  Future<void> remove(DateTime start) async {
    final s = dateOnly(start);
    await _commit(state.where((l) => dateOnly(l.start) != s).toList());
  }

  Future<void> replaceAll(List<PeriodLog> logs) => _commit([...logs]);
}

final periodLogsProvider =
    NotifierProvider<PeriodLogsNotifier, List<PeriodLog>>(PeriodLogsNotifier.new);

final predictionProvider = Provider<CyclePrediction?>((ref) {
  final logs = ref.watch(periodLogsProvider);
  return ref.watch(cycleEngineProvider).predict(logs);
});

final homeSummaryProvider = Provider<HomeSummary?>((ref) {
  final p = ref.watch(predictionProvider);
  if (p == null) return null;
  return summarizeHome(ref.watch(cycleEngineProvider), p, ref.watch(todayProvider));
});

final statsProvider = Provider<CycleStats>(
  (ref) => computeStats(ref.watch(cycleEngineProvider), ref.watch(periodLogsProvider)),
);

// ---------- catatan harian ----------
class NotesNotifier extends Notifier<Map<DateTime, DayNote>> {
  @override
  Map<DateTime, DayNote> build() => {
        for (final n in ref.watch(notesRepositoryProvider).load()) n.date: n,
      };

  Future<void> _commit(Map<DateTime, DayNote> m) async {
    state = Map.unmodifiable(m);
    await ref.read(notesRepositoryProvider).save(m.values.toList());
  }

  /// Catatan kosong otomatis menghapus catatan hari itu.
  Future<void> save(DayNote n) async {
    final m = {...state};
    if (n.isEmpty) {
      m.remove(n.date);
    } else {
      m[n.date] = n;
    }
    await _commit(m);
  }

  Future<void> remove(DateTime date) async {
    final m = {...state}..remove(dateOnly(date));
    await _commit(m);
  }

  Future<void> replaceAll(List<DayNote> notes) => _commit({for (final n in notes) n.date: n});
}

final notesProvider =
    NotifierProvider<NotesNotifier, Map<DateTime, DayNote>>(NotesNotifier.new);

// ---------- pasangan ----------
class PartnerNotifier extends Notifier<PartnerState> {
  PartnerRepository get _repo => ref.read(partnerRepositoryProvider);

  @override
  PartnerState build() => const PartnerState();

  Future<void> createInvite() async {
    state = await _repo.createInvite();
  }

  /// Melempar [FormatException] bila kode tidak valid (ditangkap UI).
  Future<void> acceptInvite(String code) async {
    state = await _repo.acceptInvite(code);
  }

  Future<void> simulateAccepted() async {
    state = await _repo.simulateAccepted(state);
  }

  Future<void> setFlags(ShareFlags flags) async {
    state = state.withFlags(flags);
    await _repo.saveFlags(flags);
  }

  Future<void> revoke() async {
    state = await _repo.revoke();
  }
}

final partnerProvider = NotifierProvider<PartnerNotifier, PartnerState>(PartnerNotifier.new);

// ---------- surat cinta (love notes) ----------
class LoveNotesNotifier extends Notifier<List<LoveNote>> {
  @override
  List<LoveNote> build() => ref.watch(loveNotesRepositoryProvider).load();

  Future<void> _commit(List<LoveNote> list) async {
    state = List.unmodifiable(list);
    await ref.read(loveNotesRepositoryProvider).save(state);
  }

  Future<void> addNote({
    required String message,
    String sender = 'Pasangan',
    LoveNoteTrigger trigger = LoveNoteTrigger.anytime,
  }) async {
    final note = LoveNote(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      sender: sender,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
      trigger: trigger,
    );
    await _commit([note, ...state]);
  }

  Future<void> markAsRead(String id) async {
    await _commit([
      for (final n in state) n.id == id ? n.copyWith(isRead: true) : n,
    ]);
  }

  Future<void> sendReaction(String id, String reaction) async {
    await _commit([
      for (final n in state)
        n.id == id ? n.copyWith(reaction: reaction, isRead: true) : n,
    ]);
  }

  Future<void> deleteNote(String id) async {
    await _commit(state.where((n) => n.id != id).toList());
  }

  Future<void> replaceAll(List<LoveNote> notes) => _commit([...notes]);
}

final loveNotesProvider =
    NotifierProvider<LoveNotesNotifier, List<LoveNote>>(LoveNotesNotifier.new);

/// Memilih surat cinta paling pas untuk ditampilkan di Beranda hari ini.
/// Mengutamakan surat yang belum dibaca dan cocok dengan fase siklus saat ini.
final activeLoveNoteProvider = Provider<LoveNote?>((ref) {
  final notes = ref.watch(loveNotesProvider);
  if (notes.isEmpty) return null;
  final phase = ref.watch(homeSummaryProvider)?.phase;

  // 1. Cari yang belum dibaca dan relevan dengan fase
  final unreadForPhase = notes.where((n) => !n.isRead && n.isRelevantForPhase(phase));
  if (unreadForPhase.isNotEmpty) return unreadForPhase.first;

  // 2. Cari yang belum dibaca kapan saja
  final unreadAny = notes.where((n) => !n.isRead);
  if (unreadAny.isNotEmpty) return unreadAny.first;

  // 3. Bila semua sudah dibaca, tampilkan yang terbaru yang relevan dengan fase
  final readForPhase = notes.where((n) => n.isRelevantForPhase(phase));
  if (readForPhase.isNotEmpty) return readForPhase.first;

  return notes.first;
});
