// lib/domain/partner_models.dart
// Model berbagi data ke pasangan. Murni Dart.
// buildSnapshot() adalah SATU-SATUNYA tempat yang menyaring apa yang boleh dilihat pasangan.
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
}

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
  final String? inviteCode;
  final DateTime? inviteExpires;
  final String? partnerName;
  final ShareFlags flags;
  final PartnerSnapshot? snapshot; // untuk role viewer
  final bool demo;

  const PartnerState({
    this.role = PartnerRole.none,
    this.linked = false,
    this.inviteCode,
    this.inviteExpires,
    this.partnerName,
    this.flags = const ShareFlags(),
    this.snapshot,
    this.demo = false,
  });

  PartnerState withFlags(ShareFlags f) => PartnerState(
        role: role,
        linked: linked,
        inviteCode: inviteCode,
        inviteExpires: inviteExpires,
        partnerName: partnerName,
        flags: f,
        snapshot: snapshot,
        demo: demo,
      );
}
