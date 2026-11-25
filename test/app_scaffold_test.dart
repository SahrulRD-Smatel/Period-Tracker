// test/app_scaffold_test.dart
// Mensimulasikan layar beberapa perangkat tanpa perlu simulator.
// Angka inset & ukuran di bawah KIRA-KIRA dan bisa berubah di model baru;
// justru itu alasan kenapa tinggi status bar tidak boleh di-hardcode di aplikasi.
// Ganti `mens_app` dengan nama package di pubspec.yaml kamu.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/core/app_scaffold.dart';

class _Device {
  final String name;
  final Size size; // ukuran logis (pt/dp)
  final double top, bottom; // inset area aman
  const _Device(this.name, this.size, this.top, this.bottom);
}

const _devices = [
  _Device('iPhone 14 Pro Max', Size(430, 932), 59, 34),
  _Device('iPhone 18 Pro', Size(402, 874), 62, 34),
  _Device('iPhone 18 Pro Max', Size(440, 956), 62, 34),
  _Device('Android gesture nav', Size(412, 915), 32, 24),
];

void main() {
  for (final dev in _devices) {
    testWidgets('konten di dalam area aman: ${dev.name}', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = dev.size;
      tester.view.padding = FakeViewPadding(top: dev.top, bottom: dev.bottom);
      tester.view.viewPadding = FakeViewPadding(top: dev.top, bottom: dev.bottom);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: AppScaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('atas', key: Key('atas')),
                Text('bawah', key: Key('bawah')),
              ],
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.byKey(const Key('atas'))).dy,
          greaterThanOrEqualTo(dev.top));
      expect(tester.getBottomLeft(find.byKey(const Key('bawah'))).dy,
          lessThanOrEqualTo(dev.size.height - dev.bottom));
    });
  }
}
