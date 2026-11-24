// lib/features/home/love_letter_dialog.dart
// Tampilan modal surat cinta bergaya kertas surat coquette manis & interaktif.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/love_notes.dart';

Future<void> showLoveLetterModal(BuildContext context, WidgetRef ref, LoveNote note) {
  // Tandai sudah dibaca begitu dibuka
  if (!note.isRead) {
    ref.read(loveNotesProvider.notifier).markAsRead(note.id);
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) => _LoveLetterSheet(note: note),
  );
}

class _LoveLetterSheet extends ConsumerWidget {
  final LoveNote note;
  const _LoveLetterSheet({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil versi terbaru catatan bila reaksi berubah
    final all = ref.watch(loveNotesProvider);
    final current = all.firstWhere((n) => n.id == note.id, orElse: () => note);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.dialogShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.petal, width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Garis penarik atas
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.ribbon,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Surat
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.envelopeOpen,
                  color: AppColors.rose,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Surat Cinta 💌', style: kHeading.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      'Dari ${current.sender} • ${fmtDayMonth(current.createdAt)}',
                      style: kSmall.copyWith(color: AppColors.mauveSoft),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(PhosphorIconsRegular.x, size: 20, color: AppColors.mauveSoft),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Kertas Surat Cinta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.petal),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CoquetteBow(size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pesan untukmu hari ini:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  current.message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.mauve,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reaksi Balik
          Text(
            current.reaction != null
                ? 'Reaksi kamu: ${current.reaction} 💞'
                : 'Kirim reaksi balasan ke ${current.sender}:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mauve,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in const [
                (emoji: '💖', label: 'Sayang'),
                (emoji: '🫂', label: 'Peluk'),
                (emoji: '🥺', label: 'Terharu'),
                (emoji: '🌸', label: 'Manja'),
                (emoji: '🍫', label: 'Cokelat'),
              ])
                _ReactionBtn(
                  emoji: r.emoji,
                  isSelected: current.reaction == r.emoji,
                  onTap: () {
                    ref.read(loveNotesProvider.notifier).sendReaction(current.id, r.emoji);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reaksi ${r.emoji} ${r.label} terkirim 💞'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReactionBtn extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionBtn({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ribbon : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.rose : AppColors.petal,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      );
}
