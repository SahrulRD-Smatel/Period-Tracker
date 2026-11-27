// lib/features/onboarding/onboarding_screen.dart
// Alur pertama kali: sambutan -> kenali siklus -> haid terakhir -> siap.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../application/providers.dart';
import '../../core/adaptive.dart';
import '../../core/app_scaffold.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/app_settings.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _lastPage = 3;
  final _controller = PageController();
  int _page = 0;
  int _cycle = 28;
  int _period = 5;
  DateTime? _lastStart;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    setState(() => _page = page);
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await pickDateAdaptive(
      context,
      initial: _lastStart ?? today,
      first: today.subtract(const Duration(days: 365)),
      last: today,
      help: 'Hari pertama haid terakhir',
    );
    if (picked != null) setState(() => _lastStart = picked);
  }

  Future<void> _finish() async {
    if (_lastStart != null) {
      await ref.read(periodLogsProvider.notifier).addStart(_lastStart!);
    }
    await ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(cycleLength: _cycle, periodLength: _period, onboardingDone: true),
        );
  }

  Widget _page0() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.petal,
              shape: BoxShape.circle,
            ),
            child: const CoquetteBow(size: 48),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text('Selamat datang di Siklusku',
                  textAlign: TextAlign.center, style: kHeading.copyWith(fontSize: 30))
              .animate(delay: 150.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 10),
          const Text(
            'Teman yang lembut untuk memahami siklusmu.',
            textAlign: TextAlign.center,
            style: kSmall,
          ).animate(delay: 220.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          PinkCard(
            child: Column(
              children: [
                _Bullet(PhosphorIconsFill.heartbeat, 'Perkiraan haid, ovulasi, dan masa subur'),
                const SizedBox(height: 12),
                _Bullet(PhosphorIconsFill.lockKey, 'Datamu tersimpan di perangkat ini'),
                const SizedBox(height: 12),
                _Bullet(PhosphorIconsFill.users, 'Bisa terhubung dengan pasangan, hanya atas izinmu'),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut),
        ],
      );

  Widget _page1() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Kenali siklusmu', style: kHeading.copyWith(fontSize: 28))
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
          const SizedBox(height: 8),
          const Text(
            'Tidak tahu pasti? Biarkan nilai awal ini. Aplikasi akan menyesuaikan '
            'setelah kamu mencatat beberapa siklus.',
            textAlign: TextAlign.center,
            style: kSmall,
          ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 20),
          PinkCard(
            child: Column(
              children: [
                StepperTile(
                  title: 'Panjang siklus',
                  subtitle: 'Hari pertama haid ke haid berikutnya',
                  value: _cycle,
                  min: kCycleMin,
                  max: kCycleMax,
                  unit: 'hari',
                  onChanged: (v) => setState(() => _cycle = v),
                ),
                const Divider(height: 28, color: AppColors.petal),
                StepperTile(
                  title: 'Lama haid',
                  subtitle: 'Biasanya 3–7 hari',
                  value: _period,
                  min: kPeriodMin,
                  max: kPeriodMax,
                  unit: 'hari',
                  onChanged: (v) => setState(() => _period = v),
                ),
              ],
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut),
        ],
      );

  Widget _page2() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Kapan haid terakhirmu dimulai?',
                  textAlign: TextAlign.center, style: kHeading.copyWith(fontSize: 26))
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
          const SizedBox(height: 8),
          const Text(
            'Ini dipakai untuk menghitung perkiraan pertamamu. Boleh dilewati.',
            textAlign: TextAlign.center,
            style: kSmall,
          ).animate(delay: 80.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 20),
          PinkCard(
            child: Column(
              children: [
                Text(
                  _lastStart == null ? 'Belum dipilih' : fmtFull(_lastStart!),
                  textAlign: TextAlign.center,
                  style: kHeading.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(PhosphorIconsRegular.calendarDots),
                    label: Text(_lastStart == null ? 'Pilih tanggal' : 'Ubah tanggal'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _lastStart = null);
                    _go(_lastPage);
                  },
                  child: const Text('Lewati, nanti saja'),
                ),
              ],
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut),
        ],
      );

  Widget _page3() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.petal,
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsFill.flowerLotus, color: AppColors.rose, size: 48),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text('Siap!', style: kHeading.copyWith(fontSize: 30))
              .animate(delay: 150.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          PinkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panjang siklus: $_cycle hari'),
                const SizedBox(height: 6),
                Text('Lama haid: $_period hari'),
                const SizedBox(height: 6),
                Text(_lastStart == null
                    ? 'Haid terakhir: belum diisi'
                    : 'Haid terakhir: ${fmtDayMonth(_lastStart!)}'),
                const SizedBox(height: 6),
                const Text('Semua ini bisa diubah di Setelan.', style: kSmall),
              ],
            ),
          ).animate(delay: 220.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut),
          const SizedBox(height: 14),
          const Text(
            'Perkiraan berdasarkan kalender, bukan alat kontrasepsi dan bukan diagnosis medis.',
            textAlign: TextAlign.center,
            style: kSmall,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[_page0(), _page1(), _page2(), _page3()];
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final p in pages)
                    Center(child: SingleChildScrollView(child: p)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.rose : AppColors.ribbon,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_page > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _go(_page - 1),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _page == _lastPage ? _finish : () => _go(_page + 1),
                    child: Text(_page == _lastPage ? 'Mulai' : 'Lanjut'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconBubble(icon: icon, color: AppColors.petal, onColor: AppColors.rose),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.3))),
        ],
      );
}
