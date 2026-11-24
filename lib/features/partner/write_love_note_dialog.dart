// lib/features/partner/write_love_note_dialog.dart
// Dialog untuk menulis surat cinta dari pasangan.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/theme.dart';
import '../../domain/love_notes.dart';

Future<void> showWriteLoveNoteModal(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => const _WriteLoveNoteSheet(),
    );

class _WriteLoveNoteSheet extends ConsumerStatefulWidget {
  const _WriteLoveNoteSheet();

  @override
  ConsumerState<_WriteLoveNoteSheet> createState() => _WriteLoveNoteSheetState();
}

class _WriteLoveNoteSheetState extends ConsumerState<_WriteLoveNoteSheet> {
  final _controller = TextEditingController();
  LoveNoteTrigger _trigger = LoveNoteTrigger.anytime;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyTemplate(String text, LoveNoteTrigger trigger) {
    setState(() {
      _controller.text = text;
      _trigger = trigger;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await ref.read(loveNotesProvider.notifier).addNote(
          message: text,
          sender: 'Pasangan',
          trigger: _trigger,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat cinta tersimpan & terkirim ke Beranda 💌'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.petal, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.dialogShadow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ribbon,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(PhosphorIconsFill.notePencil, color: AppColors.rose, size: 24),
                const SizedBox(width: 10),
                Text('Tulis Surat Cinta 💌', style: kHeading.copyWith(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesan manis ini akan muncul dalam bentuk amplop berpita di Beranda pasanganmu.',
              style: kSmall,
            ),
            const SizedBox(height: 14),

            // Pilihan template cepat
            const Text(
              'Gunakan template cepat:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mauveSoft),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in kLoveNoteTemplates)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(t.title, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.blush,
                        side: const BorderSide(color: AppColors.petal),
                        onPressed: () => _applyTemplate(t.text, t.trigger),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Input teks pesan
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tuliskan pesan penuh kasih sayang untuknya di sini...',
                hintStyle: kSmall.copyWith(color: AppColors.mauveSoft),
                filled: true,
                fillColor: AppColors.blush.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.petal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.petal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Kapan surat ditampilkan
            Row(
              children: [
                const Text('Momen muncul: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                DropdownButton<LoveNoteTrigger>(
                  value: _trigger,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(16),
                  items: const [
                    DropdownMenuItem(
                      value: LoveNoteTrigger.anytime,
                      child: Text('Kapan Saja ✨', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: LoveNoteTrigger.menstrual,
                      child: Text('Saat Haid 🌸', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: LoveNoteTrigger.luteal,
                      child: Text('Saat PMS 🫂', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _trigger = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Kirim
            FilledButton.icon(
              onPressed: _send,
              icon: const Icon(PhosphorIconsFill.paperPlaneTilt),
              label: const Text('Kirim Surat Cinta'),
            ),
          ],
        ),
      ),
    );
  }
}
