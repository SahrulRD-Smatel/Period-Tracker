// lib/domain/partner_models.dart
// Model berbagi data ke pasangan. Murni Dart.
// buildSnapshot() adalah SATU-SATUNYA tempat yang menyaring apa yang boleh dilihat pasangan.
import 'backup.dart' show isoDate;
import 'cycle_engine.dart';
import 'home_summary.dart';

class ShareFlags {
  final bool phase, fertileWindow, nextPeriod;
  const ShareFlags({this.phase = true, this.fertileWindow = true, this.nextPeriod = true});

  ShareFlags copyWith({bool? phase, bool? fertileWindow, bool? nextPeriod}) => ShareFlags(
        phase: phase ?? this.phase,
        fertileWindow: fertileWindow ?? this.fertileWindow,
        nextPeriod: nextPeriod ?? this.nextPeriod,
      );

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'fertileWindow': fertileWindow,
        'nextPeriod': nextPeriod,
      };

  factory ShareFlags.fromJson(Map<dynamic, dynamic> j) => ShareFlags(
        phase: j['phase'] as bool? ?? true,
        fertileWindow: j['fertileWindow'] as bool? ?? true,
        nextPeriod: j['nextPeriod'] as bool? ?? true,
      );
}

DateTime? _tryDate(dynamic v) => v is String && v.isNotEmpty ? dateOnly(DateTime.parse(v)) : null;

/// Ringkasan yang dilihat pasangan. Tidak pernah memuat gejala, mood, atau riwayat mentah.
class PartnerSnapshot {
  final CyclePhase? phase;
  final int? cycleDay;
  final DateTime? nextPeriod;
  final Lateness? lateness;
  final DateTime? fertileStart, fertileEnd, ovulation;
  final DateTime updatedAt;
  const PartnerSnapshot({
    this.phase,
    this.cycleDay,
    this.nextPeriod,
    this.lateness,
    this.fertileStart,
    this.fertileEnd,
    this.ovulation,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        if (phase != null) 'phase': phase!.name,
        if (cycleDay != null) 'cycleDay': cycleDay,
        if (nextPeriod != null) 'nextPeriod': isoDate(nextPeriod!),
        if (lateness != null) 'lateness': lateness!.name,
        if (fertileStart != null) 'fertileStart': isoDate(fertileStart!),
        if (fertileEnd != null) 'fertileEnd': isoDate(fertileEnd!),
        if (ovulation != null) 'ovulation': isoDate(ovulation!),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory PartnerSnapshot.fromJson(Map<dynamic, dynamic> j) {
    final pName = j['phase'] as String?;
    final lName = (j['lateness'] as String?);
    final np = j['nextPeriod'] ?? j['next_period'];
    final fs = j['fertileStart'] ?? j['fertile_start'];
    final fe = j['fertileEnd'] ?? j['fertile_end'];
    final ov = j['ovulation'];
    final cd = j['cycleDay'] ?? j['cycle_day'];
    final ua = j['updatedAt'] ?? j['updated_at'];
    return PartnerSnapshot(
      phase: CyclePhase.values.where((e) => e.name == pName).firstOrNull,
      cycleDay: (cd as num?)?.toInt(),
      nextPeriod: _tryDate(np),
      lateness: Lateness.values.where((e) => e.name == lName).firstOrNull,
      fertileStart: _tryDate(fs),
      fertileEnd: _tryDate(fe),
      ovulation: _tryDate(ov),
      updatedAt: ua is String ? (DateTime.tryParse(ua) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

PartnerSnapshot buildSnapshot(HomeSummary s, ShareFlags f, DateTime now) => PartnerSnapshot(
      phase: f.phase ? s.phase : null,
      cycleDay: f.phase ? s.cycleDay : null,
      nextPeriod: f.nextPeriod ? s.nextPeriod : null,
      lateness: f.nextPeriod ? s.lateness : null,
      fertileStart: f.fertileWindow ? s.fertileStart : null,
      fertileEnd: f.fertileWindow ? s.fertileEnd : null,
      ovulation: f.fertileWindow ? s.ovulation : null,
      updatedAt: now,
    );

enum PartnerRole { none, owner, viewer }

class PartnerState {
  final PartnerRole role;
  final bool linked; // sudah tersambung (bukan sekadar kode undangan)
  final String? linkId; // UUID baris partner_links di backend
  final String? inviteCode;
  final DateTime? inviteExpires;
  final String? partnerName;
  final String myName;
  final ShareFlags flags;
  final PartnerSnapshot? snapshot; // untuk role viewer
  final bool demo;

  const PartnerState({
    this.role = PartnerRole.none,
    this.linked = false,
    this.linkId,
    this.inviteCode,
    this.inviteExpires,
    this.partnerName,
    this.myName = 'Pasangan',
    this.flags = const ShareFlags(),
    this.snapshot,
    this.demo = false,
  });

  PartnerState withFlags(ShareFlags f) => copyWith(flags: f);

  PartnerState copyWith({
    PartnerRole? role,
    bool? linked,
    String? linkId,
    String? inviteCode,
    DateTime? inviteExpires,
    String? partnerName,
    String? myName,
    ShareFlags? flags,
    PartnerSnapshot? snapshot,
    bool? demo,
    bool clearSnapshot = false,
  }) =>
      PartnerState(
        role: role ?? this.role,
        linked: linked ?? this.linked,
        linkId: linkId ?? this.linkId,
        inviteCode: inviteCode ?? this.inviteCode,
        inviteExpires: inviteExpires ?? this.inviteExpires,
        partnerName: partnerName ?? this.partnerName,
        myName: myName ?? this.myName,
        flags: flags ?? this.flags,
        snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
        demo: demo ?? this.demo,
      );

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'linked': linked,
        if (linkId != null) 'linkId': linkId,
        if (inviteCode != null) 'inviteCode': inviteCode,
        if (inviteExpires != null) 'inviteExpires': inviteExpires!.toUtc().toIso8601String(),
        if (partnerName != null) 'partnerName': partnerName,
        'myName': myName,
        'flags': flags.toJson(),
        if (snapshot != null) 'snapshot': snapshot!.toJson(),
        'demo': demo,
      };

  factory PartnerState.fromJson(Map<dynamic, dynamic> j) {
    final roleName = j['role'] as String?;
    final exp = j['inviteExpires'] as String?;
    return PartnerState(
      role: PartnerRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => PartnerRole.none,
      ),
      linked: j['linked'] as bool? ?? false,
      linkId: j['linkId'] as String?,
      inviteCode: j['inviteCode'] as String?,
      inviteExpires: exp == null ? null : DateTime.tryParse(exp),
      partnerName: j['partnerName'] as String?,
      myName: j['myName'] as String? ?? 'Pasangan',
      flags: j['flags'] is Map ? ShareFlags.fromJson(j['flags'] as Map) : const ShareFlags(),
      snapshot: j['snapshot'] is Map ? PartnerSnapshot.fromJson(j['snapshot'] as Map) : null,
      demo: j['demo'] as bool? ?? false,
    );
  }
}
