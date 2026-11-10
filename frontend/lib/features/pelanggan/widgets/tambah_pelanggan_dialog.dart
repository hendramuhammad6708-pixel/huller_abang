import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../models/pelanggan.dart';
import '../pelanggan_controller.dart';
import '../pelanggan_validator.dart';

/// Membuka dialog tambah pelanggan. Mengembalikan pelanggan baru bila
/// berhasil disimpan, atau `null` bila dibatalkan.
Future<Pelanggan?> tampilkanTambahPelanggan(
  BuildContext context, {
  required PelangganController controller,
}) => showDialog<Pelanggan>(
  context: context,
  builder: (_) => TambahPelangganDialog(controller: controller),
);

class TambahPelangganDialog extends StatefulWidget {
  final PelangganController controller;

  const TambahPelangganDialog({super.key, required this.controller});

  @override
  State<TambahPelangganDialog> createState() => _TambahPelangganDialogState();
}

class _TambahPelangganDialogState extends State<TambahPelangganDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kontak = TextEditingController();

  TipePelanggan _tipe = TipePelanggan.petani;
  bool _sedangSimpan = false;
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _kontak.dispose();
    super.dispose();
  }

  void _hapusGalat() {
    if (_galat != null) setState(() => _galat = null);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate() || _sedangSimpan) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sedangSimpan = true;
      _galat = null;
    });

    try {
      final hasil = await widget.controller.tambah(
        Pelanggan(
          nama: _nama.text.trim(),
          kontak: _kontak.text.trim(),
          tipe: _tipe,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, hasil);
    } on ApiJawaban catch (e) {
      if (!mounted) return;
      setState(() {
        _sedangSimpan = false;
        _galat = e.errors.values.firstOrNull ?? e.pesan;
      });
    }
  }

  IconData _ikonTipe(TipePelanggan tipe) => switch (tipe) {
    TipePelanggan.petani => Icons.grass_rounded,
    TipePelanggan.pengepul => Icons.local_shipping_outlined,
    TipePelanggan.milikHuller => Icons.warehouse_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Pelanggan Baru'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_galat != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sedang),
                    border: Border.all(color: AppColors.dangerLine),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _galat!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                key: const Key('field-nama-pelanggan-baru'),
                controller: _nama,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _hapusGalat(),
                decoration: const InputDecoration(
                  labelText: 'Nama pelanggan',
                  hintText: 'Contoh: Pak Warsito',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: PelangganValidator.nama,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('field-kontak-pelanggan-baru'),
                controller: _kontak,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _hapusGalat(),
                onFieldSubmitted: (_) => _simpan(),
                decoration: const InputDecoration(
                  labelText: 'No. HP (opsional)',
                  hintText: '081234567890',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: PelangganValidator.kontak,
              ),
              const SizedBox(height: 20),
              const Text(
                'Tipe pelanggan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              RadioGroup<TipePelanggan>(
                groupValue: _tipe,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _tipe = v);
                  _hapusGalat();
                },
                child: Column(
                  children: [
                    for (final t in TipePelanggan.values) ...[
                      RadioListTile<TipePelanggan>(
                        key: Key('tipe-baru-${t.nilaiApi}'),
                        value: t,
                        enabled: !_sedangSimpan,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sedang),
                        ),
                        tileColor: _tipe == t
                            ? AppColors.mint.withValues(alpha: 0.5)
                            : null,
                        controlAffinity: ListTileControlAffinity.trailing,
                        secondary: Icon(
                          _ikonTipe(t),
                          color: t == TipePelanggan.milikHuller
                              ? AppColors.gold
                              : AppColors.primary,
                        ),
                        title: Text(
                          t.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (t != TipePelanggan.values.last)
                        const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sedangSimpan ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('btn-simpan-pelanggan-baru'),
          onPressed: _sedangSimpan ? null : _simpan,
          child: _sedangSimpan
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
