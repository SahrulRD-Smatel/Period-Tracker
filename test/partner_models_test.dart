// test/partner_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mens_app/data/partner_repository.dart';
import 'package:mens_app/domain/cycle_engine.dart';
import 'package:mens_app/domain/home_summary.dart';
import 'package:mens_app/domain/partner_models.dart';

void main() {
  const engine = CycleEngine();
  DateTime d(int m, int day) => DateTime.utc(2026, m, day);
  final summary = summarizeHome(
    engine,
    engine.predict([PeriodLog(start: d(1, 1))])!,
    d(1, 10),
  )!;

  test('semua dibagikan -> snapshot lengkap', () {
    final s = buildSnapshot(summary, const ShareFlags(), d(1, 10));
    expect(s.phase, CyclePhase.fertile);
    expect(s.cycleDay, 10);
    expect(s.nextPeriod, d(1, 29));
    expect(s.fertileStart, d(1, 10));
    expect(s.ovulation, d(1, 15));
  });

  test('flag dimatikan -> field itu null (privasi disaring di domain)', () {
    final s = buildSnapshot(
      summary,
      const ShareFlags(phase: false, fertileWindow: false, nextPeriod: true),
      d(1, 10),
    );
    expect(s.phase, isNull);
    expect(s.cycleDay, isNull);
    expect(s.fertileStart, isNull);
    expect(s.fertileEnd, isNull);
    expect(s.ovulation, isNull);
    expect(s.nextPeriod, d(1, 29));
    expect(s.lateness, Lateness.none);
  });

  test('repository demo: undangan 8 karakter, terima kode valid / tolak kode salah', () async {
    final repo = DemoPartnerRepository(now: () => DateTime.utc(2026, 3, 10));
    final invite = await repo.createInvite();
    expect(invite.role, PartnerRole.owner);
    expect(invite.inviteCode!.length, 8);

    final viewer = await repo.acceptInvite('abcd2345');
    expect(viewer.role, PartnerRole.viewer);
    expect(viewer.linked, isTrue);
    expect(viewer.snapshot, isNotNull);

    expect(() => repo.acceptInvite('SALAH'), throwsFormatException);
    expect(() => repo.acceptInvite('ABCD234O'), throwsFormatException); // huruf O tidak dipakai
  });

  test('revoke mengembalikan keadaan kosong', () async {
    final s = await DemoPartnerRepository().revoke();
    expect(s.role, PartnerRole.none);
    expect(s.linked, isFalse);
  });
}
