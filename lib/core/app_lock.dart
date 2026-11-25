// lib/core/app_lock.dart
// Overlay kunci aplikasi menggunakan biometrik / PIN perangkat, dengan PIN 4-digit fallback lokal.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../application/providers.dart';
import 'theme.dart';

final _auth = LocalAuthentication();

class AppLockService {
  AppLockService._();

  static Future<bool> isHardwareSupported() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Coba autentikasi hardware (biometrik/PIN OS). Mengembalikan false bila gagal atau tidak didukung.
  static Future<bool> authenticateHardware() async {
    try {
      final supported = await isHardwareSupported();
      if (!supported) return false;
      return await _auth.authenticate(
        localizedReason: 'Autentikasi untuk membuka Siklusku dan melindungi privasi data kesehatanmu.',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

/// Dialog pengaturan PIN 4-digit lokal untuk perangkat tanpa biometrik (atau PIN cadangan).
Future<String?> promptSetLocalPin(BuildContext context) => showDialog<String>(
      context: context,
      builder: (_) => const _SetPinDialog(),
    );

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog();

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _ctrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(v)) {
      setState(() => _err = 'Masukkan tepat 4 digit angka.');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Buat PIN Siklusku (4 angka)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perangkat ini tidak memiliki kunci biometrik aktif. Buat PIN 4 angka agar layar kunci benar-benar melindungi datamu.',
              style: kSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: 'Contoh: 1234',
                errorText: _err,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          FilledButton(onPressed: _submit, child: const Text('Simpan PIN')),
        ],
      );
}

/// Widget pembungkus yang menampilkan layar kunci bila [locked] = true.
class AppLockOverlay extends StatelessWidget {
  final bool locked;
  final VoidCallback onUnlock;
  final Widget child;

  const AppLockOverlay({
    super.key,
    required this.locked,
    required this.onUnlock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (locked) _LockScreen(onUnlock: onUnlock),
      ],
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  bool _loading = false;
  bool _hwSupported = false;
  bool _hasPin = false;
  bool _checkedSupport = false;
  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _hasPin = ref.read(appPinRepositoryProvider).hasPin;
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final hw = await AppLockService.isHardwareSupported();
    final hasPin = ref.read(appPinRepositoryProvider).hasPin;
    if (!mounted) return;
    setState(() {
      _hwSupported = hw;
      _hasPin = hasPin;
      _checkedSupport = true;
    });
    if (hw) {
      await _tryHardwareAuth();
    } else if (!hasPin) {
      // Hanya bila dipulihkan dari backup perangkat lain ke perangkat tanpa biometrik & belum ada PIN
      widget.onUnlock();
    }
  }

  Future<void> _tryHardwareAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AppLockService.authenticateHardware();
    if (!mounted) return;
    if (ok) {
      widget.onUnlock();
    } else {
      setState(() {
        _loading = false;
        _error = 'Autentikasi dibatalkan atau gagal. Coba lagi.';
      });
    }
  }

  void _tapDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) {
      final ok = ref.read(appPinRepositoryProvider).verify(_pin);
      if (ok) {
        widget.onUnlock();
      } else {
        setState(() {
          _pin = '';
          _error = 'PIN salah. Coba lagi ya.';
        });
      }
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final showPinPad = _hasPin || (_checkedSupport && !_hwSupported);
    return Material(
      color: AppColors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: AppColors.petal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showPinPad ? PhosphorIconsRegular.lockKey : PhosphorIconsRegular.fingerprint,
                    size: 40,
                    color: AppColors.rose,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      duration: 450.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 22),
                Text(
                  'Siklusku terkunci',
                  style: kHeading.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  showPinPad
                      ? 'Masukkan PIN 4 angka untuk membuka aplikasi.'
                      : 'Gunakan sidik jari, Face ID, atau PIN perangkat untuk membuka.',
                  textAlign: TextAlign.center,
                  style: kSmall,
                ),
                const SizedBox(height: 24),
                if (showPinPad) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _pin.length ? AppColors.rose : AppColors.track,
                            border: Border.all(
                              color: i < _pin.length ? AppColors.rose : AppColors.ribbon,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  SizedBox(
                    width: 240,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        for (final d in const ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                          _PinKey(label: d, onTap: () => _tapDigit(d)),
                        const SizedBox(width: 64, height: 64),
                        _PinKey(label: '0', onTap: () => _tapDigit('0')),
                        _PinKey(
                          icon: PhosphorIconsRegular.backspace,
                          onTap: _backspace,
                        ),
                      ],
                    ),
                  ),
                  if (_hwSupported) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _loading ? null : _tryHardwareAuth,
                      icon: const Icon(PhosphorIconsRegular.fingerprint),
                      label: const Text('Pakai biometrik perangkat'),
                    ),
                  ],
                ] else ...[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _tryHardwareAuth,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(PhosphorIconsRegular.lockOpen),
                      label: Text(_loading ? 'Memverifikasi...' : 'Buka kunci'),
                    ),
                  ),
                ],
              ],
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
          ),
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _PinKey({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blush,
            border: Border.all(color: AppColors.petal),
          ),
          child: label != null
              ? Text(label!, style: kHeading.copyWith(fontSize: 22))
              : Icon(icon, color: AppColors.mauve, size: 22),
        ),
      );
}
