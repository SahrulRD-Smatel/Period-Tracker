// lib/features/partner/partner_widgets.dart
// Tampilan ringkasan siklus yang dilihat pasangan (dipakai juga untuk pratinjau pemilik).
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../core/formatters.dart';
import '../../core/phase_style.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/care_guide.dart';
import '../../domain/cycle_engine.dart';
import '../../domain/partner_models.dart';
import 'write_love_note_dialog.dart';

/// Saran dukungan untuk pasangan per fase.
String partnerTip(CyclePhase? phase) => switch (phase) {
      CyclePhase.menstrual =>
        'Tanyakan kabarnya dan tawarkan perhatian manis: minuman hangat, camilan favorit, atau waktu istirahat yang cukup.',
      CyclePhase.follicular => 'Energinya sedang baik dan ceria. Waktu yang pas untuk jalan-jalan santai atau ngobrol seru.',
      CyclePhase.fertile =>
        'Kondisinya sedang aktif dan bersemangat. Nikmati momen kebersamaan dengan suasana yang hangat dan menyenangkan.',
      CyclePhase.ovulation =>
        'Kondisinya sedang prima. Berikan apresiasi tulus dan obrolan manis yang membahagiakan hatinya.',
      CyclePhase.luteal =>
        'Menjelang haid (PMS), suasana hatinya mungkin lebih sensitif atau mudah lelah. Dengarkan dengan penuh pengertian dan beri pelukan hangat.',
      CyclePhase.delayed =>
        'Haidnya belum datang dari perkiraan. Beri ketenangan dan rasa aman tanpa menekan atau membuat cemas.',
      null => 'Tidak ada fase yang dibagikan saat ini.',
    };

class PartnerSnapshotView extends StatelessWidget {
  final PartnerSnapshot snapshot;
  final DateTime today;
  const PartnerSnapshotView({super.key, required this.snapshot, required this.today});

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    return Column(
      children: [
        _phaseTile(s),
        const SizedBox(height: 12),
        _periodTile(s),
        const SizedBox(height: 12),
        _fertileTile(s),
        const SizedBox(height: 8),
        Text('Diperbarui ${fmtDayMonth(s.updatedAt)}', style: kSmall),
      ],
    );
  }

  Widget _phaseTile(PartnerSnapshot s) {
    if (s.phase == null) return const _HiddenTile('Fase siklus tidak dibagikan');
    final st = phaseStyle(s.phase!);
    return PinkCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: st.icon, color: st.color, onColor: st.onColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kondisi hari ini', style: kSmall),
                const SizedBox(height: 4),
                PhaseChip(label: st.label, icon: st.icon, color: st.color, onColor: st.onColor),
                const SizedBox(height: 6),
                if (s.cycleDay != null) Text('Hari ke-${s.cycleDay} siklus', style: kSmall),
                Text(st.hint, style: kSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodTile(PartnerSnapshot s) {
    if (s.nextPeriod == null) return const _HiddenTile('Perkiraan haid tidak dibagikan');
    final d = s.nextPeriod!.difference(today).inDays;
    final big = d > 1
        ? '$d hari lagi'
        : d == 1
            ? 'Besok'
            : d == 0
                ? 'Hari ini'
                : 'Terlambat ${-d} hari';
    return PinkCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(icon: PhosphorIconsFill.drop, color: AppColors.rose, onColor: AppColors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d >= 0 ? 'Perkiraan haid berikutnya' : 'Haid belum datang', style: kSmall),
                Text(big, style: kHeading.copyWith(fontSize: 26)),
                Text('Sekitar ${fmtDayMonth(s.nextPeriod!)}', style: kSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fertileTile(PartnerSnapshot s) {
    if (s.fertileStart == null || s.fertileEnd == null) {
      return const _HiddenTile('Masa subur tidak dibagikan');
    }
    final String title;
    if (today.isBefore(s.fertileStart!)) {
      final n = s.fertileStart!.difference(today).inDays;
      title = n == 1 ? 'Masa subur besok' : 'Masa subur $n hari lagi';
    } else if (!today.isAfter(s.fertileEnd!)) {
      title = 'Sedang masa subur';
    } else {
      title = 'Masa subur sudah lewat';
    }
    return PinkCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(icon: PhosphorIconsFill.heart, color: AppColors.lilac, onColor: AppColors.mauve),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kHeading.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  '${fmtRange(s.fertileStart!, s.fertileEnd!)}'
                  '${s.ovulation != null ? ' · ovulasi ±${fmtDayMonth(s.ovulation!)}' : ''}',
                  style: kSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenTile extends StatelessWidget {
  final String text;
  const _HiddenTile(this.text);

  @override
  Widget build(BuildContext context) => PinkCard(
        color: AppColors.blush,
        child: Row(
          children: [
            const Icon(PhosphorIconsRegular.lock, color: AppColors.mist),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: kSmall)),
          ],
        ),
      );
}

class CareChecklistCard extends StatefulWidget {
  final CyclePhase? phase;
  final String? partnerName;

  const CareChecklistCard({super.key, required this.phase, this.partnerName});

  @override
  State<CareChecklistCard> createState() => _CareChecklistCardState();
}

class _CareChecklistCardState extends State<CareChecklistCard> {
  final Set<String> _checkedIds = {};

  @override
  Widget build(BuildContext context) {
    final items = careGuideForPhase(widget.phase);
    final total = items.length;
    final done = _checkedIds.length;
    final progress = total > 0 ? done / total : 0.0;
    final name = widget.partnerName ?? 'Pasangan';

    return PinkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.petal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.handHeart,
                  color: AppColors.rose,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Checklist Perhatian Romantis 🎀', style: kHeading.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text('Panduan kasih sayang untuk menemani $name', style: kSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.petal,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.rose),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perhatian terwujud: $done dari $total',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.rose),
              ),
              if (done == total && total > 0)
                const Text('Luar biasa manis! 🥰', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.rose)),
            ],
          ),
          const SizedBox(height: 12),

          // Checklist items
          for (final item in items) ...[
            InkWell(
              onTap: () {
                setState(() {
                  if (_checkedIds.contains(item.id)) {
                    _checkedIds.remove(item.id);
                  } else {
                    _checkedIds.add(item.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _checkedIds.contains(item.id)
                      ? AppColors.blush.withValues(alpha: 0.5)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _checkedIds.contains(item.id) ? AppColors.rose : AppColors.petal,
                    width: _checkedIds.contains(item.id) ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: _checkedIds.contains(item.id)
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: _checkedIds.contains(item.id)
                                  ? AppColors.mauveSoft
                                  : AppColors.mauve,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: kSmall.copyWith(
                              color: _checkedIds.contains(item.id)
                                  ? AppColors.mauveSoft
                                  : AppColors.mauve,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _checkedIds.contains(item.id)
                          ? PhosphorIconsFill.checkCircle
                          : PhosphorIconsRegular.circle,
                      color: _checkedIds.contains(item.id)
                          ? AppColors.rose
                          : AppColors.mist,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Tombol Tulis Surat Cinta
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => showWriteLoveNoteModal(context),
              icon: const Icon(PhosphorIconsFill.envelopeOpen),
              label: Text('Kirim Surat Cinta untuk $name 💌'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.petal,
                foregroundColor: AppColors.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
