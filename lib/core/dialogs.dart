// lib/core/dialogs.dart
// Dialog konfirmasi adaptif: gaya Cupertino di iOS, Material 3 di Android.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'platform_ui.dart';
import 'theme.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (ctx) {
      final ios = isCupertino(ctx);
      return AlertDialog.adaptive(
        title: Text(title),
        content: Text(message),
        actions: ios
            ? [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  isDestructiveAction: destructive,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    confirmLabel,
                    style: TextStyle(
                      color: destructive ? AppColors.danger : AppColors.rose,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
      );
    },
  );
  return result ?? false;
}
