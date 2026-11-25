// lib/data/supabase_partner_repository.dart
// Implementasi nyata sinkronisasi 2 HP untuk fitur Pasangan menggunakan Supabase
// (Anonymous Auth + Postgres + Row Level Security + Supabase Realtime).
import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/love_notes.dart';
import '../domain/partner_models.dart';
import 'partner_repository.dart';

/// Mengelola siklus hidup inisialisasi Supabase (bisa saat boot atau runtime dari UI Setelan/Pasangan).
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static String _activeUrl = '';
  static String _activeKey = '';

  static bool get isInitialized => _initialized;
  static String get activeUrl => _activeUrl;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase belum diinisialisasi.');
    }
    return Supabase.instance.client;
  }

  /// Inisialisasi Supabase dengan URL & Publishable/Anon Key. Aman dipanggil ulang bila konfigurasi berubah.
  static Future<bool> connect({
    required String url,
    required String publishableKey,
  }) async {
    final cleanUrl = url.trim();
    final cleanKey = publishableKey.trim();
    if (!cleanUrl.startsWith('https://') || cleanKey.isEmpty) {
      throw const FormatException('URL harus diawali https:// dan Anon/Publishable Key wajib diisi.');
    }

    if (_initialized && _activeUrl == cleanUrl && _activeKey == cleanKey) {
      await ensureSignedIn();
      return true;
    }

    if (_initialized) {
      try {
        await Supabase.instance.dispose();
      } catch (_) {}
      _initialized = false;
    }

    await Supabase.initialize(
      url: cleanUrl,
      publishableKey: cleanKey,
    );
    _initialized = true;
    _activeUrl = cleanUrl;
    _activeKey = cleanKey;

    await ensureSignedIn();
    return true;
  }

  /// Putuskan koneksi server di sesi aktif.
  static Future<void> disconnect() async {
    if (_initialized) {
      try {
        await Supabase.instance.dispose();
      } catch (_) {}
      _initialized = false;
      _activeUrl = '';
      _activeKey = '';
    }
  }

  /// Pastikan perangkat punya identitas anonim Supabase (`auth.uid()`) yang persisten.
  static Future<User> ensureSignedIn() async {
    final auth = client.auth;
    if (auth.currentUser != null) return auth.currentUser!;
    final res = await auth.signInAnonymously();
    final user = res.user;
    if (user == null) {
      throw const FormatException(
        'Gagal login anonim ke Supabase. Pastikan "Anonymous Sign-Ins" aktif di dashboard Supabase Auth.',
      );
    }
    return user;
  }
}

class SupabasePartnerRepository extends PartnerRepository {
  final SupabaseClient _db;
  SupabasePartnerRepository(this._db);

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  bool get isDemo => false;

  Future<String> _uid() async {
    final user = await SupabaseService.ensureSignedIn();
    return user.id;
  }

  ShareFlags _flagsFromRow(Map<String, dynamic> row) => ShareFlags(
        phase: row['share_phase'] as bool? ?? true,
        fertileWindow: row['share_fertile'] as bool? ?? true,
        nextPeriod: row['share_next_period'] as bool? ?? true,
      );

  Future<PartnerSnapshot?> _fetchOwnerSnapshot(String ownerId) async {
    final row = await _db
        .from('cycle_snapshots')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();
    if (row == null) return null;
    return PartnerSnapshot.fromJson(row);
  }

  @override
  Future<PartnerState> restoreOrSync(PartnerState cached) async {
    try {
      final uid = await _uid();

      // 1. Cek link aktif (baik sebagai pemilik maupun pelihat)
      final link = await _db
          .from('partner_links')
          .select()
          .eq('status', 'active')
          .or('owner_id.eq.$uid,partner_id.eq.$uid')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (link != null) {
        final isOwner = link['owner_id'] == uid;
        final flags = _flagsFromRow(link);
        if (isOwner) {
          return PartnerState(
            role: PartnerRole.owner,
            linked: true,
            linkId: link['id'] as String?,
            partnerName: link['partner_name'] as String? ?? 'Pasangan',
            myName: link['owner_name'] as String? ?? cached.myName,
            flags: flags,
            demo: false,
          );
        } else {
          final snap = await _fetchOwnerSnapshot(link['owner_id'] as String);
          return PartnerState(
            role: PartnerRole.viewer,
            linked: true,
            linkId: link['id'] as String?,
            partnerName: link['owner_name'] as String? ?? 'Pasangan',
            myName: link['partner_name'] as String? ?? cached.myName,
            flags: flags,
            snapshot: snap,
            demo: false,
          );
        }
      }

      // 2. Cek apakah ada undangan yang masih berlaku
      final invite = await _db
          .from('invites')
          .select()
          .eq('owner_id', uid)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (invite != null) {
        return PartnerState(
          role: PartnerRole.owner,
          linked: false,
          inviteCode: invite['code'] as String?,
          inviteExpires: DateTime.tryParse(invite['expires_at'] as String? ?? ''),
          myName: invite['owner_name'] as String? ?? cached.myName,
          flags: cached.flags,
          demo: false,
        );
      }

      return PartnerState(myName: cached.myName, demo: false);
    } catch (_) {
      // Bila offline sementara, pertahankan cache lokal yang terakhir diketahui
      return cached.copyWith(demo: false);
    }
  }

  @override
  Future<PartnerState> createInvite({String myName = 'Pasangan'}) async {
    final uid = await _uid();
    final rnd = Random.secure();
    final code = List.generate(8, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join();
    final expires = DateTime.now().toUtc().add(const Duration(hours: 24));
    final cleanName = myName.trim().isEmpty ? 'Pasangan' : myName.trim();

    await _db.from('invites').delete().eq('owner_id', uid);
    await _db.from('invites').insert({
      'code': code,
      'owner_id': uid,
      'owner_name': cleanName,
      'expires_at': expires.toIso8601String(),
    });

    return PartnerState(
      role: PartnerRole.owner,
      linked: false,
      inviteCode: code,
      inviteExpires: expires,
      myName: cleanName,
      demo: false,
    );
  }

  @override
  Future<PartnerState> acceptInvite(String code, {String myName = 'Pasangan'}) async {
    final c = code.trim().toUpperCase();
    if (c.length != 8) {
      throw const FormatException('Kode harus 8 karakter.');
    }
    await _uid();
    final cleanName = myName.trim().isEmpty ? 'Pasangan' : myName.trim();

    try {
      final res = await _db.rpc(
        'accept_invite',
        params: {'p_code': c, 'p_partner_name': cleanName},
      );
      final rawMap = res is List ? res.first : res;
      final link = Map<String, dynamic>.from(rawMap as Map);
      final snap = await _fetchOwnerSnapshot(link['owner_id'] as String);
      return PartnerState(
        role: PartnerRole.viewer,
        linked: true,
        linkId: link['id'] as String?,
        partnerName: link['owner_name'] as String? ?? 'Pasangan',
        myName: link['partner_name'] as String? ?? cleanName,
        flags: _flagsFromRow(link),
        snapshot: snap,
        demo: false,
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('self_link')) {
        throw const FormatException('Tidak bisa menautkan kode undangan ke HP yang sama.');
      }
      if (e.message.contains('invalid_or_expired')) {
        throw const FormatException('Kode tidak valid atau sudah kedaluwarsa.');
      }
      throw FormatException('Gagal menyambungkan: ${e.message}');
    }
  }

  @override
  Future<void> saveFlags(ShareFlags flags, {PartnerState? current}) async {
    final uid = await _uid();
    await _db
        .from('partner_links')
        .update({
          'share_phase': flags.phase,
          'share_fertile': flags.fertileWindow,
          'share_next_period': flags.nextPeriod,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('owner_id', uid)
        .eq('status', 'active');
  }

  @override
  Future<void> pushSnapshot(PartnerSnapshot snapshot, {PartnerState? current}) async {
    final uid = await _uid();
    String? iso(DateTime? d) => d?.toIso8601String().substring(0, 10);
    await _db.from('cycle_snapshots').upsert({
      'owner_id': uid,
      'phase': snapshot.phase?.name,
      'cycle_day': snapshot.cycleDay,
      'lateness': snapshot.lateness?.name,
      'next_period': iso(snapshot.nextPeriod),
      'fertile_start': iso(snapshot.fertileStart),
      'fertile_end': iso(snapshot.fertileEnd),
      'ovulation': iso(snapshot.ovulation),
      'updated_at': snapshot.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<PartnerState> revoke() async {
    final uid = await _uid();
    await _db
        .from('partner_links')
        .update({
          'status': 'revoked',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('status', 'active')
        .or('owner_id.eq.$uid,partner_id.eq.$uid');
    await _db.from('invites').delete().eq('owner_id', uid);
    return const PartnerState(demo: false);
  }

  @override
  Future<PartnerState> simulateAccepted(PartnerState current) =>
      throw UnsupportedError('Gunakan kode di HP kedua pada mode server nyata.');

  @override
  Stream<PartnerState> watchPartnerState(PartnerState current) {
    late StreamController<PartnerState> controller;
    RealtimeChannel? channel;
    Timer? debounce;

    Future<void> refresh() async {
      final next = await restoreOrSync(current);
      if (!controller.isClosed) {
        controller.add(next);
      }
    }

    controller = StreamController<PartnerState>(
      onListen: () {
        channel = _db
            .channel('siklusku_sync_${DateTime.now().microsecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'partner_links',
              callback: (_) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 250), refresh);
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'cycle_snapshots',
              callback: (_) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 250), refresh);
              },
            )
            .subscribe();
      },
      onCancel: () async {
        debounce?.cancel();
        if (channel != null) {
          await _db.removeChannel(channel!);
        }
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<LoveNote>> watchLoveNotes(String linkId) {
    return _db
        .from('love_notes')
        .stream(primaryKey: ['id'])
        .eq('link_id', linkId)
        .order('created_at', ascending: false)
        .map((rows) => [
              for (final r in rows)
                LoveNote(
                  id: r['id'] as String? ?? '',
                  sender: r['sender_name'] as String? ?? 'Pasangan',
                  message: r['message'] as String? ?? '',
                  createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
                  isRead: r['is_read'] as bool? ?? false,
                  trigger: LoveNoteTrigger.values.firstWhere(
                    (t) => t.name == (r['trigger'] as String?),
                    orElse: () => LoveNoteTrigger.anytime,
                  ),
                  reaction: r['reaction'] as String?,
                ),
            ]);
  }

  @override
  Future<void> sendLoveNote({required String linkId, required LoveNote note}) async {
    final uid = await _uid();
    await _db.from('love_notes').upsert({
      'id': note.id,
      'link_id': linkId,
      'sender_id': uid,
      'sender_name': note.sender,
      'message': note.message,
      'trigger': note.trigger.name,
      'reaction': note.reaction,
      'is_read': note.isRead,
      'created_at': note.createdAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> reactLoveNote({required String noteId, required String reaction}) async {
    await _db.from('love_notes').update({'reaction': reaction, 'is_read': true}).eq('id', noteId);
  }

  @override
  Future<void> markLoveNoteRead({required String noteId}) async {
    await _db.from('love_notes').update({'is_read': true}).eq('id', noteId);
  }

  @override
  Stream<Set<String>> watchCareProgress(String linkId) {
    return _db
        .from('care_progress')
        .stream(primaryKey: ['link_id'])
        .eq('link_id', linkId)
        .map((rows) {
          if (rows.isEmpty) return <String>{};
          final raw = rows.first['checked_ids'] as List? ?? const [];
          return {for (final x in raw) x as String};
        });
  }

  @override
  Future<void> saveCareProgress({required String linkId, required Set<String> checkedIds}) async {
    await _db.from('care_progress').upsert({
      'link_id': linkId,
      'checked_ids': checkedIds.toList()..sort(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
