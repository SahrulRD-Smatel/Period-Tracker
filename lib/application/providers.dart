// lib/application/providers.dart
// Alur data: periodLogs/notes/settings -> engine -> prediction -> homeSummary / stats / dayView -> UI,
// serta sinkronisasi Pasangan & Surat Cinta (lokal / Supabase realtime).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cycle_repository.dart';
import '../data/local_store.dart';
import '../data/partner_repository.dart';
import '../data/supabase_partner_repository.dart';
import '../domain/app_settings.dart';
import '../domain/cycle_engine.dart';
import '../domain/cycle_sync.dart';
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
final careChecklistRepositoryProvider = Provider<CareChecklistRepository>(
  (ref) => PrefsCareChecklistRepository(ref.watch(sharedPrefsProvider)),
);
final partnerStateRepositoryProvider = Provider<PartnerStateRepository>(
  (ref) => PrefsPartnerStateRepository(ref.watch(sharedPrefsProvider)),
);
final serverConfigRepositoryProvider = Provider<ServerConfigRepository>(
  (ref) => PrefsServerConfigRepository(ref.watch(sharedPrefsProvider)),
);
final appPinRepositoryProvider = Provider<PrefsAppPinRepository>(
  (ref) => PrefsAppPinRepository(ref.watch(sharedPrefsProvider)),
);

// ---------- konfigurasi server 2 HP (Supabase) ----------
class ServerConfigNotifier extends Notifier<ServerConfig> {
  @override
  ServerConfig build() => ref.watch(serverConfigRepositoryProvider).load();

  Future<void> save(ServerConfig next) async {
    state = next;
    await ref.read(serverConfigRepositoryProvider).save(next);
  }
}

final serverConfigProvider =
    NotifierProvider<ServerConfigNotifier, ServerConfig>(ServerConfigNotifier.new);

class SupabaseConnectedNotifier extends Notifier<bool> {
  @override
  bool build() => SupabaseService.isInitialized;

  Future<void> connect(ServerConfig config) async {
    final enabledCfg = config.copyWith(cloudEnabled: true);
    await SupabaseService.connect(
      url: enabledCfg.supabaseUrl,
      publishableKey: enabledCfg.supabaseAnonKey,
    );
    await ref.read(serverConfigProvider.notifier).save(enabledCfg);
    state = true;
  }

  Future<void> disconnect() async {
    await SupabaseService.disconnect();
    await ref.read(serverConfigProvider.notifier).save(
          ref.read(serverConfigProvider).copyWith(
                supabaseUrl: '',
                supabaseAnonKey: '',
                cloudEnabled: false,
              ),
        );
    state = false;
  }
}

final supabaseConnectedProvider =
    NotifierProvider<SupabaseConnectedNotifier, bool>(SupabaseConnectedNotifier.new);

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  final ready = ref.watch(supabaseConnectedProvider);
  final cfg = ref.watch(serverConfigProvider);
  if (ready && cfg.isConfigured && SupabaseService.isInitialized) {
    return SupabasePartnerRepository(SupabaseService.client);
  }
  return DemoPartnerRepository();
});

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

  Future<void> setEnd(DateTime start, DateTime? end) async {
    final s = dateOnly(start);
    final e = end == null ? null : dateOnly(end);
    if (e != null && e.isBefore(s)) return;
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

final predictionProvider = Provider<CyclePrediction?>((ref) {
  final logs = ref.watch(periodLogsProvider);
  final notes = ref.watch(notesProvider).values;
  final confirmedOv = latestConfirmedOvulation(logs, notes);
  return ref.watch(cycleEngineProvider).predict(logs, confirmedOvulation: confirmedOv);
});

final homeSummaryProvider = Provider<HomeSummary?>((ref) {
  final p = ref.watch(predictionProvider);
  if (p == null) return null;
  return summarizeHome(ref.watch(cycleEngineProvider), p, ref.watch(todayProvider));
});

final statsProvider = Provider<CycleStats>(
  (ref) => computeStats(
    ref.watch(cycleEngineProvider),
    ref.watch(periodLogsProvider),
    notes: ref.watch(notesProvider).values.toList(),
  ),
);

// ---------- pasangan ----------
class PartnerNotifier extends Notifier<PartnerState> {
  PartnerRepository get _repo => ref.read(partnerRepositoryProvider);
  PartnerStateRepository get _cache => ref.read(partnerStateRepositoryProvider);
  StreamSubscription<PartnerState>? _sub;

  @override
  PartnerState build() {
    final repo = ref.watch(partnerRepositoryProvider);
    final cached = ref.watch(partnerStateRepositoryProvider).load();

    _sub?.cancel();
    _sub = null;

    if (!repo.isDemo) {
      Future.microtask(() => syncWithServer());
      final stream = repo.watchPartnerState(cached);
      if (stream != null) {
        _sub = stream.listen(
          (next) {
            state = next;
            _cache.save(next);
            if (next.role == PartnerRole.owner && next.linked) {
              pushSnapshotIfOwner();
            }
          },
          onError: (_) {},
        );
      }
      ref.onDispose(() {
        _sub?.cancel();
        _sub = null;
      });
    }

    return cached;
  }

  Future<void> _save(PartnerState next) async {
    state = next;
    await _cache.save(next);
  }

  Future<void> syncWithServer() async {
    if (_repo.isDemo) return;
    final synced = await _repo.restoreOrSync(state);
    await _save(synced);
    if (synced.role == PartnerRole.owner && synced.linked) {
      await pushSnapshotIfOwner();
    }
  }

  Future<void> createInvite() async {
    final myName = ref.read(serverConfigProvider).displayName;
    final next = await _repo.createInvite(myName: myName);
    await _save(next);
  }

  /// Melempar [FormatException] bila kode tidak valid (ditangkap UI).
  Future<void> acceptInvite(String code) async {
    final myName = ref.read(serverConfigProvider).displayName;
    final next = await _repo.acceptInvite(code, myName: myName);
    await _save(next);
  }

  Future<void> simulateAccepted() async {
    final next = await _repo.simulateAccepted(state);
    await _save(next);
  }

  Future<void> setFlags(ShareFlags flags) async {
    final next = state.withFlags(flags);
    await _save(next);
    await _repo.saveFlags(flags, current: next);
    await pushSnapshotIfOwner();
  }

  Future<void> pushSnapshotIfOwner() async {
    if (state.role != PartnerRole.owner || !state.linked) return;
    final summary = ref.read(homeSummaryProvider);
    if (summary == null) return;
    final snap = buildSnapshot(summary, state.flags, DateTime.now());
    try {
      await _repo.pushSnapshot(snap, current: state);
    } catch (_) {}
  }

  Future<void> revoke() async {
    final next = await _repo.revoke();
    await _save(next);
  }

  Future<void> resetLocalCache() async {
    await _cache.clear();
    state = const PartnerState();
  }
}

final partnerProvider = NotifierProvider<PartnerNotifier, PartnerState>(PartnerNotifier.new);

// ---------- checklist perhatian romantis (persisten + tersinkron) ----------
class CareChecklistNotifier extends Notifier<Set<String>> {
  StreamSubscription<Set<String>>? _sub;

  @override
  Set<String> build() {
    final repo = ref.watch(partnerRepositoryProvider);
    final partner = ref.watch(partnerProvider);
    final local = ref.watch(careChecklistRepositoryProvider).load();

    _sub?.cancel();
    _sub = null;

    if (!repo.isDemo && partner.linked && partner.linkId != null) {
      final stream = repo.watchCareProgress(partner.linkId!);
      if (stream != null) {
        _sub = stream.listen(
          (remoteIds) {
            state = Set.unmodifiable(remoteIds);
            ref.read(careChecklistRepositoryProvider).save(state);
          },
          onError: (_) {},
        );
      }
      ref.onDispose(() {
        _sub?.cancel();
        _sub = null;
      });
    }

    return Set.unmodifiable(local);
  }

  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.add(id)) {
      next.remove(id);
    }
    state = Set.unmodifiable(next);
    await ref.read(careChecklistRepositoryProvider).save(state);

    final repo = ref.read(partnerRepositoryProvider);
    final partner = ref.read(partnerProvider);
    if (!repo.isDemo && partner.linked && partner.linkId != null) {
      try {
        await repo.saveCareProgress(linkId: partner.linkId!, checkedIds: state);
      } catch (_) {}
    }
  }

  Future<void> replaceAll(Set<String> ids) async {
    state = Set.unmodifiable(ids);
    await ref.read(careChecklistRepositoryProvider).save(state);
  }
}

final careChecklistProvider =
    NotifierProvider<CareChecklistNotifier, Set<String>>(CareChecklistNotifier.new);

// ---------- surat cinta (love notes) ----------
class LoveNotesNotifier extends Notifier<List<LoveNote>> {
  StreamSubscription<List<LoveNote>>? _sub;

  @override
  List<LoveNote> build() {
    final repo = ref.watch(partnerRepositoryProvider);
    final partner = ref.watch(partnerProvider);
    final local = ref.watch(loveNotesRepositoryProvider).load();

    _sub?.cancel();
    _sub = null;

    if (!repo.isDemo && partner.linked && partner.linkId != null) {
      final stream = repo.watchLoveNotes(partner.linkId!);
      if (stream != null) {
        _sub = stream.listen(
          (remoteNotes) {
            if (remoteNotes.isNotEmpty) {
              state = List.unmodifiable(remoteNotes);
              ref.read(loveNotesRepositoryProvider).save(state);
            }
          },
          onError: (_) {},
        );
      }
      ref.onDispose(() {
        _sub?.cancel();
        _sub = null;
      });
    }

    return local;
  }

  Future<void> _commit(List<LoveNote> list) async {
    state = List.unmodifiable(list);
    await ref.read(loveNotesRepositoryProvider).save(state);
  }

  Future<void> addNote({
    required String message,
    String? sender,
    LoveNoteTrigger trigger = LoveNoteTrigger.anytime,
  }) async {
    final cfgName = ref.read(serverConfigProvider).displayName;
    final cleanSender = (sender != null && sender.trim().isNotEmpty) ? sender.trim() : cfgName;
    final note = LoveNote(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      sender: cleanSender,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
      trigger: trigger,
    );
    await _commit([note, ...state]);

    final repo = ref.read(partnerRepositoryProvider);
    final partner = ref.read(partnerProvider);
    if (!repo.isDemo && partner.linked && partner.linkId != null) {
      await repo.sendLoveNote(linkId: partner.linkId!, note: note);
    }
  }

  Future<void> markAsRead(String id) async {
    await _commit([
      for (final n in state) n.id == id ? n.copyWith(isRead: true) : n,
    ]);
    final repo = ref.read(partnerRepositoryProvider);
    final partner = ref.read(partnerProvider);
    if (!repo.isDemo && partner.linked && partner.linkId != null) {
      try {
        await repo.markLoveNoteRead(noteId: id);
      } catch (_) {}
    }
  }

  Future<void> sendReaction(String id, String reaction) async {
    await _commit([
      for (final n in state)
        n.id == id ? n.copyWith(reaction: reaction, isRead: true) : n,
    ]);
    final repo = ref.read(partnerRepositoryProvider);
    final partner = ref.read(partnerProvider);
    if (!repo.isDemo && partner.linked && partner.linkId != null) {
      try {
        await repo.reactLoveNote(noteId: id, reaction: reaction);
      } catch (_) {}
    }
  }

  Future<void> deleteNote(String id) async {
    await _commit(state.where((n) => n.id != id).toList());
  }

  Future<void> replaceAll(List<LoveNote> notes) => _commit([...notes]);
}

final loveNotesProvider =
    NotifierProvider<LoveNotesNotifier, List<LoveNote>>(LoveNotesNotifier.new);

/// Memilih surat cinta paling pas untuk ditampilkan di Beranda hari ini.
final activeLoveNoteProvider = Provider<LoveNote?>((ref) {
  final notes = ref.watch(loveNotesProvider);
  if (notes.isEmpty) return null;
  final phase = ref.watch(homeSummaryProvider)?.phase;

  final unreadForPhase = notes.where((n) => !n.isRead && n.isRelevantForPhase(phase));
  if (unreadForPhase.isNotEmpty) return unreadForPhase.first;

  final unreadAny = notes.where((n) => !n.isRead);
  if (unreadAny.isNotEmpty) return unreadAny.first;

  final readForPhase = notes.where((n) => n.isRelevantForPhase(phase));
  if (readForPhase.isNotEmpty) return readForPhase.first;

  return notes.first;
});
