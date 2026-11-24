// lib/domain/love_notes.dart
// Model surat cinta & pesan penyemangat dari pasangan. Murni Dart.

import 'cycle_engine.dart';

enum LoveNoteTrigger {
  menstrual, // Saat haid
  luteal,    // Saat PMS
  anytime,   // Kapan saja
}

class LoveNote {
  final String id;
  final String sender;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final LoveNoteTrigger trigger;
  final String? reaction; // Reaksi balik dari penerima (mis. '💖', '🌸', '🫂', '🍫')

  const LoveNote({
    required this.id,
    this.sender = 'Pasangan',
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.trigger = LoveNoteTrigger.anytime,
    this.reaction,
  });

  LoveNote copyWith({
    String? id,
    String? sender,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    LoveNoteTrigger? trigger,
    String? reaction,
  }) =>
      LoveNote(
        id: id ?? this.id,
        sender: sender ?? this.sender,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        trigger: trigger ?? this.trigger,
        reaction: reaction ?? this.reaction,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'trigger': trigger.name,
        'reaction': reaction,
      };

  factory LoveNote.fromJson(Map<dynamic, dynamic> j) => LoveNote(
        id: j['id'] as String? ?? '',
        sender: j['sender'] as String? ?? 'Pasangan',
        message: j['message'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        isRead: j['isRead'] as bool? ?? false,
        trigger: LoveNoteTrigger.values.firstWhere(
          (t) => t.name == (j['trigger'] as String?),
          orElse: () => LoveNoteTrigger.anytime,
        ),
        reaction: j['reaction'] as String?,
      );

  /// Cek apakah surat ini relevan dengan fase siklus hari ini.
  bool isRelevantForPhase(CyclePhase? phase) {
    if (trigger == LoveNoteTrigger.anytime) return true;
    if (trigger == LoveNoteTrigger.menstrual && phase == CyclePhase.menstrual) return true;
    if (trigger == LoveNoteTrigger.luteal && phase == CyclePhase.luteal) return true;
    return false;
  }
}

/// Template pesan romantis siap pakai untuk mempermudah pasangan.
const kLoveNoteTemplates = [
  (
    title: 'Penenang Kram Haid 🌸',
    trigger: LoveNoteTrigger.menstrual,
    text: 'Istirahat yang banyak ya sayang. Kalau perutnya sakit, jangan dipaksa beraktivitas. Nanti malam aku bawain makanan favoritmu dan temani kamu sampai enakan 🎀',
  ),
  (
    title: 'Peluk Hangat PMS 🫂',
    trigger: LoveNoteTrigger.luteal,
    text: 'Hari ini mungkin perasaanmu lagi campur aduk atau sensitif, but it is okay. Kamu selalu luar biasa di mataku. Peluk hangat dari jauh untuk wanitaku tersayang 🥰',
  ),
  (
    title: 'Pemberi Semangat Kapan Saja 💖',
    trigger: LoveNoteTrigger.anytime,
    text: 'Cuma mau mengingatkan: aku bangga dan bersyukur punya kamu. Jangan lupa minum air putih dan tersenyum hari ini manis! ✨',
  ),
  (
    title: 'Cokelat & Manis-manis 🍫',
    trigger: LoveNoteTrigger.menstrual,
    text: 'Perut kram butuh yang manis-manis! Nanti kabari ya kamu lagi pengen camilan apa, biar langsung aku siapin khusus buat kamu 🍫🤍',
  ),
];
