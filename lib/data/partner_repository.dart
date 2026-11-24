// lib/data/partner_repository.dart
// Kontrak berbagi data ke pasangan + implementasi DEMO (tanpa server, hanya di memori).
// Implementasi nyata (Supabase) ada sebagai rancangan di docs/future/partner_repository.dart.txt.
import 'dart:math';

import '../domain/cycle_engine.dart';
import '../domain/home_summary.dart';
import '../domain/partner_models.dart';

abstract class PartnerRepository {
  /// Pemilik data membuat undangan.
  Future<PartnerState> createInvite();

  /// Pasangan memasukkan kode. Melempar [FormatException] bila kode tidak valid.
  Future<PartnerState> acceptInvite(String code);

  /// Menyimpan pilihan data yang dibagikan.
  Future<void> saveFlags(ShareFlags flags);

  /// Pemilik mencabut akses / pasangan memutus koneksi.
  Future<PartnerState> revoke();

  /// HANYA demo: anggap pasangan sudah menerima undangan.
  Future<PartnerState> simulateAccepted(PartnerState current);
}

class DemoPartnerRepository implements PartnerRepository {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // tanpa 0/O/1/I
  final DateTime Function() _now;
  DemoPartnerRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  @override
  Future<PartnerState> createInvite() async {
    final rnd = Random.secure();
    final code = List.generate(8, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join();
    return PartnerState(
      role: PartnerRole.owner,
      inviteCode: code,
      inviteExpires: _now().add(const Duration(hours: 24)),
      demo: true,
    );
  }

  @override
  Future<PartnerState> acceptInvite(String code) async {
    final c = code.trim().toUpperCase();
    final valid = c.length == 8 && c.split('').every((ch) => _alphabet.contains(ch));
    if (!valid) {
      throw const FormatException('Kode harus 8 karakter (huruf besar dan angka).');
    }
    return PartnerState(
      role: PartnerRole.viewer,
      linked: true,
      partnerName: 'Pasangan',
      snapshot: _sampleSnapshot(),
      demo: true,
    );
  }

  @override
  Future<void> saveFlags(ShareFlags flags) async {}

  @override
  Future<PartnerState> revoke() async => const PartnerState();

  @override
  Future<PartnerState> simulateAccepted(PartnerState current) async => PartnerState(
        role: PartnerRole.owner,
        linked: true,
        partnerName: 'Pasangan',
        flags: current.flags,
        demo: true,
      );

  /// Contoh data untuk tampilan pasangan (hari ke-13 dari siklus 28 hari).
  PartnerSnapshot _sampleSnapshot() {
    const engine = CycleEngine();
    final now = _now();
    final today = dateOnly(now);
    final p = engine.predict([PeriodLog(start: today.subtract(const Duration(days: 12)))])!;
    return buildSnapshot(summarizeHome(engine, p, today)!, const ShareFlags(), now);
  }
}
