// lib/core/formatters.dart
// Format tanggal Indonesia. Pastikan initializeDateFormatting('id_ID') dipanggil di main()/tes.
import 'package:intl/intl.dart';

const _locale = 'id_ID';

String fmtDayMonth(DateTime d) => DateFormat('d MMM', _locale).format(d);
String fmtFull(DateTime d) => DateFormat('EEEE, d MMMM y', _locale).format(d);

String fmtRange(DateTime a, DateTime b) =>
    a.month == b.month ? '${a.day}–${fmtDayMonth(b)}' : '${fmtDayMonth(a)} – ${fmtDayMonth(b)}';
