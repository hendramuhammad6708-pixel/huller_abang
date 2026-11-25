import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Dialog pembatalan (void) transaksi. Meminta alasan minimal 3 karakter.
/// Mengembalikan alasan (sudah dipangkas) atau null bila dibatalkan.
Future<String?> konfirmasiVoid(
  BuildContext context, {
  required String judul,
  required String pesan,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogVoid(judul: judul, pesan: pesan),
  );
}

class _DialogVoid extends StatefulWidget {
  final String judul;
  final String pesan;

  const _DialogVoid({required this.judul, required this.pesan});

  @override
  State<_DialogVoid> createState() => _DialogVoidState();
}

class _DialogVoidState extends State<_DialogVoid> {
  final _formKey = GlobalKey<FormState>();
  final _alasan = TextEditingController();

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  String? _validasi(String? v) {
    final teks = (v ?? '').trim();
    if (teks.isEmpty) return 'Alasan pembatalan wajib diisi';
    if (teks.length < 3) return 'Alasan minimal 3 karakter';
    if (teks.length > 255) return 'Alasan maksimal 255 karakter';
    return null;
  }

  void _kirim() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _alasan.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('dialog-konfirmasi-void'),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cancel_outlined,
          size: 28,
          color: AppColors.danger,
        ),
      ),
      title: Text(widget.judul, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('field-alasan-void'),
                controller: _alasan,
                autofocus: true,
                maxLength: 255,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _kirim(),
                validator: _validasi,
                decoration: const InputDecoration(
                  labelText: 'Alasan pembatalan',
                  hintText: 'Mis. salah input berat',
                ),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          key: const Key('btn-batal-void'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali'),
        ),
        FilledButton(
          key: const Key('btn-konfirmasi-void'),
          onPressed: _kirim,
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Batalkan Transaksi'),
        ),
      ],
    );
  }
}
