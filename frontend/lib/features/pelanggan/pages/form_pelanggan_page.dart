import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/konfirmasi_hapus.dart';
import '../models/pelanggan.dart';
import '../pelanggan_controller.dart';
import '../pelanggan_validator.dart';

/// Form tambah (pelanggan == null) atau ubah pelanggan — tersimpan ke API.
/// Menutup halaman dengan pesan sukses untuk ditampilkan di daftar.
class FormPelangganPage extends StatefulWidget {
  final PelangganController controller;
  final Pelanggan? pelanggan;

  const FormPelangganPage({
    super.key,
    required this.controller,
    this.pelanggan,
  });

  @override
  State<FormPelangganPage> createState() => _FormPelangganPageState();
}

class _FormPelangganPageState extends State<FormPelangganPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.pelanggan?.nama);
  late final _kontak = TextEditingController(text: widget.pelanggan?.kontak);
  late TipePelanggan _tipe = widget.pelanggan?.tipe ?? TipePelanggan.petani;

  bool _sedangSimpan = false;

  bool get _ubah => widget.pelanggan != null;

  @override
  void dispose() {
    _nama.dispose();
    _kontak.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate() || _sedangSimpan) return;
    setState(() => _sedangSimpan = true);

    final data = Pelanggan(
      id: widget.pelanggan?.id,
      nama: _nama.text.trim(),
      kontak: _kontak.text.trim(),
      tipe: _tipe,
    );

    try {
      if (_ubah) {
        await widget.controller.ubah(data);
        if (mounted) Navigator.pop(context, 'Data ${data.nama} diperbarui');
      } else {
        await widget.controller.tambah(data);
        if (mounted) Navigator.pop(context, '${data.nama} ditambahkan');
      }
    } on ApiJawaban catch (e) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      // Validasi 422: tampilkan pesan per field dari backend
      final galatNama = e.errors['nama'];
      final galatKontak = e.errors['kontak'];
      if (galatNama != null || galatKontak != null) {
        _formKey.currentState?.validate();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(galatNama ?? galatKontak ?? e.pesan),
          backgroundColor: const Color(0xFFD64545),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.pesan),
          backgroundColor: const Color(0xFFD64545),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _hapus() async {
    final p = widget.pelanggan!;
    final ok = await konfirmasiHapus(
      context,
      judul: 'Hapus pelanggan?',
      pesan: '${p.nama} akan dihapus dari daftar pelanggan.',
    );
    if (!ok || !mounted) return;
    try {
      await widget.controller.hapus(p.id!);
      if (mounted) Navigator.pop(context, '${p.nama} dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.pesan),
          backgroundColor: const Color(0xFFD64545),
        ));
      }
    }
  }

  InputDecoration _dekor(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primaryLight, 1.5),
        errorBorder: _border(const Color(0xFFD64545)),
        focusedErrorBorder: _border(const Color(0xFFD64545), 1.5),
      );

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ubah ? 'Ubah Pelanggan' : 'Pelanggan Baru',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_ubah)
            IconButton(
              tooltip: 'Hapus pelanggan',
              onPressed: _hapus,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFD64545)),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextFormField(
                key: const Key('field-nama'),
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _dekor('Nama pelanggan', Icons.person_outline,
                    hint: 'Contoh: Pak Warsito'),
                validator: (v) {
                  final e = PelangganValidator.nama(v);
                  if (e != null) return e;
                  // Pesan 422 backend (nama dobel dsb.) bila ada
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('field-kontak'),
                controller: _kontak,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: _dekor('No. HP (opsional)', Icons.phone_outlined,
                    hint: '081234567890'),
                validator: PelangganValidator.kontak,
              ),
              const SizedBox(height: 20),
              const Text('Tipe pelanggan',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              SegmentedButton<TipePelanggan>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: TipePelanggan.petani,
                    icon: Icon(Icons.grass_rounded),
                    label: Text('Petani'),
                  ),
                  ButtonSegment(
                    value: TipePelanggan.pengepul,
                    icon: Icon(Icons.local_shipping_outlined),
                    label: Text('Pengepul'),
                  ),
                  ButtonSegment(
                    value: TipePelanggan.milikHuller,
                    icon: Icon(Icons.warehouse_outlined),
                    label: Text('Milik Huller'),
                  ),
                ],
                selected: {_tipe},
                onSelectionChanged: (s) => setState(() => _tipe = s.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: AppColors.mint,
                  selectedForegroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                key: const Key('btn-simpan'),
                onPressed: _sedangSimpan ? null : _simpan,
                icon: _sedangSimpan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_ubah ? 'Simpan Perubahan' : 'Simpan Pelanggan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
