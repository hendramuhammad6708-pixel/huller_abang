import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Dialog konfirmasi hapus. Mengembalikan true bila pengguna menekan "Hapus".
Future<bool> konfirmasiHapus(
  BuildContext context, {
  required String judul,
  required String pesan,
  String labelHapus = 'Hapus',
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
            color: AppColors.dangerSoft, shape: BoxShape.circle),
        child: const Icon(Icons.delete_outline_rounded,
            size: 28, color: AppColors.danger),
      ),
      title: Text(judul, textAlign: TextAlign.center),
      content: Text(pesan,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: Text(labelHapus),
        ),
      ],
    ),
  );
  return hasil ?? false;
}
