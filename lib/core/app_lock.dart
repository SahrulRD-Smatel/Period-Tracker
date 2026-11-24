// lib/core/app_lock.dart
// Overlay kunci aplikasi menggunakan biometrik / PIN perangkat.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'theme.dart';

final _auth = LocalAuthentication();

class AppLockService {
  AppLockService._();

  /// Kembalikan true bila autentikasi berhasil atau tidak tersedia.
  static Future<bool> authenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
      if (!canCheck) return true; // perangkat tidak mendukung → lewati
      return await _auth.authenticate(
        localizedReason: 'Autentikasi untuk membuka Siklusku dan melindungi privasi data kesehatanmu.',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
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

class _LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _tryAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AppLockService.authenticate();
    if (!mounted) return;
    if (ok) {
      widget.onUnlock();
    } else {
      setState(() {
        _loading = false;
        _error = 'Autentikasi gagal. Coba lagi.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Langsung minta autentikasi saat layar kunci muncul
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuth());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.petal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.fingerprint,
                    size: 44,
                    color: AppColors.rose,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: 28),
                Text(
                  'Siklusku terkunci',
                  style: kHeading.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan sidik jari, Face ID, atau PIN perangkat untuk membuka.',
                  textAlign: TextAlign.center,
                  style: kSmall,
                ),
                const SizedBox(height: 32),
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
                    onPressed: _loading ? null : _tryAuth,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : const Icon(PhosphorIconsRegular.lockOpen),
                    label: Text(_loading ? 'Memverifikasi...' : 'Buka kunci'),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
          ),
        ),
      ),
    );
  }
}
