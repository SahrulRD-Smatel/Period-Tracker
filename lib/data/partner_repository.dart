// lib/data/partner_repository.dart
// Kontrak berbagi data ke pasangan + implementasi lokal/demo serta dukungan realtime 2 HP.
import 'dart:math';

import '../domain/cycle_engine.dart';
import '../domain/home_summary.dart';
import '../domain/love_notes.dart';
import '../domain/partner_models.dart';

abstract class PartnerRepository {
  bool get isDemo;

  /// Sinkronisasi ulang status koneksi & snapshot saat aplikasi dibuka atau kembali aktif.
  Future<PartnerState> restoreOrSync(PartnerState cached);

  /// Pemilik data membuat undangan 8 karakter.
  Future<PartnerState> createInvite({String myName = 'Pasangan'});

  /// Pasangan memasukkan kode. Melempar [FormatException] bila kode tidak valid.
  Future<PartnerState> acceptInvite(String code, {String myName = 'Pasangan'});

  /// Menyimpan pilihan data yang dibagikan.
  Future<void> saveFlags(ShareFlags flags, {PartnerState? current});

  /// Mengirim snapshot tersaring dari pemilik ke server (no-op di mode demo).
  Future<void> pushSnapshot(PartnerSnapshot snapshot, {PartnerState? current});

  /// Pemilik mencabut akses / pasangan memutus koneksi.
  Future<PartnerState> revoke();

  /// HANYA demo: anggap pasangan sudah menerima undangan di perangkat ini.
  Future<PartnerState> simulateAccepted(PartnerState current);

  /// Aliran realtime status pasangan & snapshot (null pada mode demo).
  Stream<PartnerState>? watchPartnerState(PartnerState current) => null;

  /// Aliran realtime surat cinta antar 2 HP (null pada mode demo).
  Stream<List<LoveNote>>? watchLoveNotes(String linkId) => null;
  Future<void> sendLoveNote({required String linkId, required LoveNote note}) async {}
  Future<void> reactLoveNote({required String noteId, required String reaction}) async {}
  Future<void> markLoveNoteRead({required String noteId}) async {}

  /// Aliran realtime progres checklist perhatian (null pada mode demo).
  Stream<Set<String>>? watchCareProgress(String linkId) => null;
  Future<void> saveCareProgress({required String linkId, required Set<String> checkedIds}) async {}
}

class DemoPartnerRepository extends PartnerRepository {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // tanpa 0/O/1/I
  final DateTime Function() _now;
  DemoPartnerRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  @override
  bool get isDemo => true;

  @override
  Future<PartnerState> restoreOrSync(PartnerState cached) async => cached;

  @override
  Future<PartnerState> createInvite({String myName = 'Pasangan'}) async {
    final rnd = Random.secure();
    final code = List.generate(8, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join();
    return PartnerState(
      role: PartnerRole.owner,
      inviteCode: code,
      inviteExpires: _now().add(const Duration(hours: 24)),
      myName: myName,
      demo: true,
    );
  }

  @override
  Future<PartnerState> acceptInvite(String code, {String myName = 'Pasangan'}) async {
    final c = code.trim().toUpperCase();
    final valid = c.length == 8 && c.split('').every((ch) => _alphabet.contains(ch));
    if (!valid) {
      throw const FormatException('Kode harus 8 karakter (huruf besar dan angka).');
    }
    return PartnerState(
      role: PartnerRole.viewer,
      linked: true,
      partnerName: 'Pasangan (Demo)',
      myName: myName,
      snapshot: _sampleSnapshot(),
      demo: true,
    );
  }

  @override
  Future<void> saveFlags(ShareFlags flags, {PartnerState? current}) async {}

  @override
  Future<void> pushSnapshot(PartnerSnapshot snapshot, {PartnerState? current}) async {}

  @override
  Future<PartnerState> revoke() async => const PartnerState();

  @override
  Future<PartnerState> simulateAccepted(PartnerState current) async => PartnerState(
        role: PartnerRole.owner,
        linked: true,
        partnerName: 'Pasangan',
        myName: current.myName,
        flags: current.flags,
        demo: true,
      );

  /// Contoh data untuk tampilan pasangan mode demo (hari ke-13 dari siklus 28 hari).
  PartnerSnapshot _sampleSnapshot() {
    const engine = CycleEngine();
    final now = _now();
    final today = dateOnly(now);
    final p = engine.predict([PeriodLog(start: today.subtract(const Duration(days: 12)))])!;
    return buildSnapshot(summarizeHome(engine, p, today)!, const ShareFlags(), now);
  }
}
