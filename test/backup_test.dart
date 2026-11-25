// test/backup_test.dart
// Ganti `mens_app` dengan nama package di pubspec.yaml kamu.
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/backup.dart';
import 'package:period_tracker/domain/cycle_engine.dart';

void main() {
  DateTime d(int m, int day) => DateTime.utc(2026, m, day);

  test('ekspor lalu impor menghasilkan data yang sama', () {
    final logs = [PeriodLog(start: d(1, 1), end: d(1, 5)), PeriodLog(start: d(1, 29))];
    final back = importBackup(exportBackup(logs));
    expect(back.length, 2);
    expect(back[0].start, d(1, 1));
    expect(back[0].end, d(1, 5));
    expect(back[1].start, d(1, 29));
    expect(back[1].end, isNull);
  });

  test('berkas rusak / versi tak dikenal ditolak', () {
    expect(() => importBackup('{"version":99,"periods":[]}'), throwsFormatException);
    expect(() => importBackup('[]'), throwsFormatException);
  });
}
