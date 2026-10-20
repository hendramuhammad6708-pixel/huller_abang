import 'package:flutter/material.dart';

/// Dialog konfirmasi hapus. Mengembalikan true bila pengguna menekan "Hapus".
Future<bool> konfirmasiHapus(
  BuildContext context, {
  required String judul,
  required String pesan,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.delete_outline_rounded,
          size: 32, color: Color(0xFFD64545)),
      title: Text(judul, textAlign: TextAlign.center),
      content: Text(pesan, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545)),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return hasil ?? false;
}
