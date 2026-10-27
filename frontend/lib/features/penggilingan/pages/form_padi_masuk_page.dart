import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../pelanggan/models/pelanggan.dart';
import '../../pelanggan/pelanggan_controller.dart';
import '../../pengaturan/pengaturan_controller.dart';
import '../models/padi_masuk.dart';
import '../padi_masuk_controller.dart';
import '../padi_masuk_validator.dart';

/// Form catat padi masuk — tersimpan ke API.
/// "Simpan" menutup halaman dengan pesan sukses; "Simpan & Catat Lagi"
/// mengosongkan berat/catatan dan mempertahankan pelanggan, kelas, tanggal.
class FormPadiMasukPage extends StatefulWidget {
  final PadiMasukController controller;
  final PelangganController pelanggan;
  final PengaturanController pengaturan;

  const FormPadiMasukPage({
    super.key,
    required this.controller,
    required this.pelanggan,
    required this.pengaturan,
  });

  @override
  State<FormPadiMasukPage> createState() => _FormPadiMasukPageState();
}

class _FormPadiMasukPageState extends State<FormPadiMasukPage> {
  final _formKey = GlobalKey<FormState>();
  final _berat = TextEditingController();
  final _catatan = TextEditingController();

  int? _pelangganId;
  int? _kelasId;
  DateTime _tanggal = DateTime.now();
  bool _sedangSimpan = false;

  @override
  void initState() {
    super.initState();
    // Jaga-jaga bila daftar belum sempat dimuat saat form dibuka
    widget.pelanggan.muat();
    widget.pengaturan.muat();
  }

  @override
  void dispose() {
    _berat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _snack(String pesan, {bool galat = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(pesan),
        backgroundColor: galat ? const Color(0xFFD64545) : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(sekarang.year - 5),
      lastDate: DateTime(sekarang.year, sekarang.month, sekarang.day),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _pilihPelanggan() async {
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PilihPelangganSheet(
        daftar: widget.pelanggan.items.where((p) => p.id != null).toList(),
      ),
    );
    if (id != null) setState(() => _pelangganId = id);
  }

  Future<void> _simpan({required bool lagi}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_sedangSimpan) return;

    if (_pelangganId == null) {
      _snack('Pelanggan wajib dipilih dari daftar', galat: true);
      return;
    }
    if (_kelasId == null) {
      _snack('Kelas padi wajib dipilih', galat: true);
      return;
    }

    setState(() => _sedangSimpan = true);

    final beratParsed = PadiMasukValidator.parseBerat(_berat.text);
    if (beratParsed == null || beratParsed <= 0) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      _snack('Berat basah wajib diisi', galat: true);
      return;
    }

    Pelanggan? pelanggan;
    try {
      pelanggan = widget.pelanggan.items.firstWhere((p) => p.id == _pelangganId);
    } catch (_) {
      pelanggan = null;
    }
    if (pelanggan == null) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      _snack('Pelanggan tidak valid, pilih kembali dari daftar', galat: true);
      return;
    }

    final kelasList = widget.pengaturan.kelas;
    final kelas = kelasList.where((k) => k.id == _kelasId).firstOrNull;
    if (kelas == null) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      _snack('Kelas padi tidak valid, pilih kembali', galat: true);
      return;
    }

    final data = PadiMasuk(
      tanggal: _tanggal,
      pelangganId: _pelangganId!,
      pelangganNama: pelanggan.nama,
      kelasId: _kelasId!,
      kelasNama: kelas.nama,
      beratKg: beratParsed,
      catatan: _catatan.text.trim(),
    );

    try {
      await widget.controller.tambah(data);
      if (!mounted) return;
      final pesan = 'Padi masuk ${pelanggan.nama} dicatat';
      if (lagi) {
        setState(() => _sedangSimpan = false);
        _berat.clear();
        _catatan.clear();
        _formKey.currentState!.reset();
        _snack(pesan);
      } else {
        Navigator.pop(context, pesan);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      String pesan = 'Gagal menyimpan padi masuk';
      if (e is ApiJawaban) {
        pesan = e.errors['berat_basah_kg'] ??
            e.errors['berat_kg'] ??
            e.errors['pelanggan_id'] ??
            e.errors['kelas_padi_id'] ??
            e.errors['tanggal'] ??
            e.errors['catatan'] ??
            (e.errors.isNotEmpty ? e.errors.values.first : null) ??
            e.pesan;
      } else {
        final s = e.toString().replaceFirst('Exception: ', '');
        pesan = s.isEmpty ? 'Gagal menyimpan padi masuk' : s;
      }
      _snack(pesan, galat: true);
    }
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  InputDecoration _dekor(String label, IconData icon,
          {String? hint, String? errorText}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primaryLight, 1.5),
        errorBorder: _border(const Color(0xFFD64545)),
        focusedErrorBorder: _border(const Color(0xFFD64545), 1.5),
      );

  Widget _judul(String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(teks,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textDark)),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.pelanggan, widget.pengaturan]),
      builder: (context, _) => _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final daftarPelanggan = widget.pelanggan.items;
    final kelas = widget.pengaturan.kelas;
    final terpilih = daftarPelanggan.where((p) => p.id == _pelangganId);
    final namaTerpilih = terpilih.isEmpty ? null : terpilih.first.nama;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Padi Masuk',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Pelanggan: ketuk untuk membuka daftar yang bisa dicari
              FormField<int>(
                key: const Key('field-pelanggan'),
                validator: (_) => PadiMasukValidator.pelanggan(_pelangganId),
                builder: (state) => InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pilihPelanggan,
                  child: InputDecorator(
                    decoration: _dekor(
                      'Pelanggan',
                      Icons.person_outline,
                      errorText: state.errorText,
                    ).copyWith(suffixIcon: const Icon(Icons.search_rounded)),
                    child: Text(
                      namaTerpilih ??
                          (daftarPelanggan.isEmpty
                              ? 'Belum ada pelanggan'
                              : 'Ketuk untuk memilih'),
                      style: TextStyle(
                        color: namaTerpilih == null
                            ? AppColors.textMuted
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Kelas: tombol pilihan, cukup satu ketukan
              FormField<int>(
                key: const Key('field-kelas'),
                validator: (_) => PadiMasukValidator.kelas(_kelasId),
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _judul('Kelas padi'),
                    if (kelas.isEmpty)
                      const Text('Belum ada kelas padi',
                          style: TextStyle(color: AppColors.textMuted)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in kelas)
                          ChoiceChip(
                            label: Text(k.nama),
                            selected: _kelasId == k.id,
                            onSelected: (_) {
                              setState(() => _kelasId = k.id);
                              state.didChange(k.id);
                            },
                            showCheckmark: false,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kelasId == k.id
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                      ],
                    ),
                    if (state.errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(state.errorText!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFD64545))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('field-berat'),
                controller: _berat,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: _dekor('Berat padi (kg)', Icons.scale_outlined,
                    hint: 'Contoh: 250,5'),
                validator: PadiMasukValidator.berat,
              ),
              const SizedBox(height: 16),
              // Tanggal otomatis hari ini; ketuk hanya bila perlu diubah
              FormField<DateTime>(
                key: const Key('field-tanggal'),
                initialValue: _tanggal,
                validator: (_) => PadiMasukValidator.tanggal(_tanggal),
                builder: (state) => InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pilihTanggal,
                  child: InputDecorator(
                    decoration: _dekor('Tanggal masuk', Icons.event_rounded,
                        errorText: state.errorText),
                    child: Text(formatTanggal(_tanggal)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('field-catatan'),
                controller: _catatan,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dekor('Catatan (opsional)', Icons.notes_rounded),
                validator: PadiMasukValidator.catatan,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                key: const Key('btn-simpan'),
                onPressed: _sedangSimpan ? null : () => _simpan(lagi: false),
                icon: _sedangSimpan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Simpan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('btn-simpan-lagi'),
                onPressed: _sedangSimpan ? null : () => _simpan(lagi: true),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Simpan & Catat Lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.primary),
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

/// Daftar pelanggan yang bisa dicari; menutup dengan id pelanggan terpilih.
class _PilihPelangganSheet extends StatefulWidget {
  final List<Pelanggan> daftar;

  const _PilihPelangganSheet({required this.daftar});

  @override
  State<_PilihPelangganSheet> createState() => _PilihPelangganSheetState();
}

class _PilihPelangganSheetState extends State<_PilihPelangganSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final hasil = widget.daftar
        .where((p) => q.isEmpty || p.nama.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                key: const Key('cari-pelanggan'),
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama pelanggan',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            Expanded(
              child: hasil.isEmpty
                  ? const Center(
                      child: Text('Pelanggan tidak ditemukan',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: hasil.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.mint,
                          foregroundColor: AppColors.mintText,
                          child: Text(hasil[i].inisial),
                        ),
                        title: Text(hasil[i].nama),
                        subtitle: Text(hasil[i].tipe.label),
                        onTap: () => Navigator.pop(context, hasil[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
