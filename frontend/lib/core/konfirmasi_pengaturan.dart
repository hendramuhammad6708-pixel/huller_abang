import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Dialog konfirmasi sebelum menyimpan persentase upah/hak operator.
/// Mengembalikan true bila pengguna menekan "Ya, Simpan".
Future<bool> konfirmasiSimpanPengaturan(BuildContext context) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('dialog-konfirmasi-pengaturan'),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.goldSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.info_outline_rounded,
          size: 28,
          color: AppColors.gold,
        ),
      ),
      title: const Text('Simpan perubahan?', textAlign: TextAlign.center),
      content: const Text(
        'Mengubah persentase hanya akan berlaku untuk transaksi baru. '
        'Transaksi yang sudah ada tidak akan berubah.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          key: const Key('btn-batal-pengaturan'),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('btn-ya-simpan'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ya, Simpan'),
        ),
      ],
    ),
  );
  return hasil ?? false;
}
