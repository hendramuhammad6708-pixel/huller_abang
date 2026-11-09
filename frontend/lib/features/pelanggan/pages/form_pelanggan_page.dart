import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/konfirmasi_hapus.dart';
import '../../../core/ui.dart';
import '../models/pelanggan.dart';
import '../pelanggan_controller.dart';
import '../pelanggan_validator.dart';
import '../widgets/pelanggan_card.dart';

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
      final galatField = e.errors['nama'] ?? e.errors['kontak'];
      tampilkanPesan(context, galatField ?? e.pesan, galat: true);
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
      if (mounted) tampilkanPesan(context, e.pesan, galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ubah ? 'Ubah Pelanggan' : 'Pelanggan Baru'),
        actions: [
          if (_ubah)
            IconButton(
              tooltip: 'Hapus pelanggan',
              onPressed: _hapus,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: BilahAksiBawah(children: [
        TombolUtama(
          key: const Key('btn-simpan'),
          label: _ubah ? 'Simpan Perubahan' : 'Simpan Pelanggan',
          icon: Icons.check_rounded,
          memuat: _sedangSimpan,
          onPressed: _simpan,
        ),
      ]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            LebarKonten(
              maks: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JudulBagian('Data pelanggan'),
                  TextFormField(
                    key: const Key('field-nama'),
                    controller: _nama,
                    autofocus: !_ubah,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama pelanggan',
                      hintText: 'Contoh: Pak Warsito',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: PelangganValidator.nama,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('field-kontak'),
                    controller: _kontak,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'No. HP (opsional)',
                      hintText: '081234567890',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: PelangganValidator.kontak,
                  ),
                  const SizedBox(height: 24),
                  const JudulBagian('Tipe pelanggan'),
                  for (final t in TipePelanggan.values) ...[
                    _PilihanTipe(
                      tipe: t,
                      terpilih: _tipe == t,
                      onTap: () => setState(() => _tipe = t),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu pilihan tipe pelanggan berupa kartu dengan penjelasan singkat.
class _PilihanTipe extends StatelessWidget {
  final TipePelanggan tipe;
  final bool terpilih;
  final VoidCallback onTap;

  const _PilihanTipe(
      {required this.tipe, required this.terpilih, required this.onTap});

  (IconData, String) get _info => switch (tipe) {
        TipePelanggan.petani =>
          (Icons.grass_rounded, 'Menggiling padi hasil panen sendiri'),
        TipePelanggan.pengepul =>
          (Icons.local_shipping_outlined, 'Membawa padi dari banyak petani'),
        TipePelanggan.milikHuller =>
          (Icons.warehouse_outlined, 'Stok padi milik huller sendiri'),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, ket) = _info;
    final sudut = BorderRadius.circular(AppRadius.sedang);
    return Material(
      color: terpilih ? AppColors.mint.withValues(alpha: 0.5) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: sudut,
        side: BorderSide(
          color: terpilih ? AppColors.primaryLight : AppColors.border,
          width: terpilih ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('tipe-${tipe.nilaiApi}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IkonKotak(icon,
                  latar: tipe.latar, warna: tipe.warna, ukuran: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tipe.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Text(ket,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(
                terpilih
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: terpilih ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
