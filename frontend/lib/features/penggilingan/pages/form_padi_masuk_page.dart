import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/sesi.dart';
import '../../../core/ui.dart';
import '../../pelanggan/models/pelanggan.dart';
import '../../pelanggan/pelanggan_controller.dart';
import '../../pelanggan/widgets/pelanggan_card.dart';
import '../../pelanggan/widgets/tambah_pelanggan_dialog.dart';
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
  final _pelangganFieldKey = GlobalKey<FormFieldState<int>>();
  final _berat = TextEditingController();
  final _catatan = TextEditingController();
  final _fokusBerat = FocusNode();

  int? _pelangganId;
  int? _kelasId;
  DateTime _tanggal = _hariIni();
  bool _sedangSimpan = false;

  static DateTime _hariIni() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

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
    _fokusBerat.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(_tanggal.year - 5),
      lastDate: _hariIni(),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _pilihPelanggan() async {
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PilihPelangganSheet(
        daftar: widget.pelanggan.items.where((p) => p.id != null).toList(),
        terpilih: _pelangganId,
      ),
    );
    if (id != null) {
      setState(() => _pelangganId = id);
      _pelangganFieldKey.currentState?.didChange(id);
    }
  }

  Future<void> _tambahPelangganBaru() async {
    final hasil = await tampilkanTambahPelanggan(
      context,
      controller: widget.pelanggan,
    );
    if (hasil == null || hasil.id == null || !mounted) return;

    setState(() => _pelangganId = hasil.id);
    _pelangganFieldKey.currentState?.didChange(hasil.id);
    tampilkanPesan(context, '${hasil.nama} ditambahkan');
  }

  Future<void> _simpan({required bool lagi}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_sedangSimpan) return;

    if (_pelangganId == null) {
      tampilkanPesan(context, 'Pelanggan wajib dipilih dari daftar', galat: true);
      return;
    }
    if (_kelasId == null) {
      tampilkanPesan(context, 'Kelas padi wajib dipilih', galat: true);
      return;
    }

    setState(() => _sedangSimpan = true);

    final beratParsed = PadiMasukValidator.parseBerat(_berat.text);
    if (beratParsed == null || beratParsed <= 0) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      tampilkanPesan(context, 'Berat basah wajib diisi', galat: true);
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
      tampilkanPesan(context, 'Pelanggan tidak valid, pilih kembali dari daftar', galat: true);
      return;
    }

    final kelasList = widget.pengaturan.kelas;
    final kelas = kelasList.where((k) => k.id == _kelasId).firstOrNull;
    if (kelas == null) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      tampilkanPesan(context, 'Kelas padi tidak valid, pilih kembali', galat: true);
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
      final pesan = 'Padi masuk ${pelanggan.nama} '
          '(${_berat.text.trim()} kg) dicatat';
      if (lagi) {
        setState(() => _sedangSimpan = false);
        _berat.clear();
        _catatan.clear();
        _formKey.currentState!.reset();
        _fokusBerat.requestFocus();
        tampilkanPesan(context, pesan);
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
      tampilkanPesan(context, pesan, galat: true);
    }
  }

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
    final terpilih =
        daftarPelanggan.where((p) => p.id == _pelangganId).firstOrNull;
    final hariIni = _hariIni();
    final kemarin = hariIni.subtract(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Padi Masuk')),
      bottomNavigationBar: BilahAksiBawah(children: [
        TombolUtama(
          key: const Key('btn-simpan'),
          label: 'Simpan',
          icon: Icons.check_rounded,
          memuat: _sedangSimpan,
          onPressed: () => _simpan(lagi: false),
        ),
        OutlinedButton.icon(
          key: const Key('btn-simpan-lagi'),
          onPressed: _sedangSimpan ? null : () => _simpan(lagi: true),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.playlist_add_rounded),
          label: const Text('Simpan & Catat Lagi'),
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
                  // Pelanggan: ketuk untuk membuka daftar yang bisa dicari
                  const JudulBagian('Pelanggan'),
                  KeyedSubtree(
                    key: const Key('field-pelanggan'),
                    child: FormField<int>(
                      key: _pelangganFieldKey,
                      validator: (_) =>
                          PadiMasukValidator.pelanggan(_pelangganId),
                      builder: (state) => InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sedang),
                        onTap: _pilihPelanggan,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.person_outline_rounded),
                            suffixIcon: const Icon(Icons.expand_more_rounded),
                            errorText: state.errorText,
                          ),
                          child: terpilih == null
                              ? Text(
                                  daftarPelanggan.isEmpty
                                      ? 'Belum ada pelanggan'
                                      : 'Pilih pelanggan',
                                  style: const TextStyle(
                                      color: AppColors.textMuted),
                                )
                              : Row(
                                  children: [
                                    Flexible(
                                      child: Text(terpilih.nama,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 8),
                                    Lencana(terpilih.tipe.label,
                                        latar: terpilih.tipe.latar,
                                        warna: terpilih.tipe.warna),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (Sesi.instance.owner) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const Key('btn-tambah-pelanggan-baru'),
                        onPressed:
                            _sedangSimpan ? null : _tambahPelangganBaru,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Tambah Pelanggan Baru'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  // Kelas: tombol pilihan, cukup satu ketukan
                  const JudulBagian('Kelas padi'),
                  FormField<int>(
                    key: const Key('field-kelas'),
                    validator: (_) => PadiMasukValidator.kelas(_kelasId),
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (kelas.isEmpty)
                          const Text(
                              'Belum ada kelas padi. Owner dapat menambahkannya '
                              'di menu Pengaturan.',
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
                              ),
                          ],
                        ),
                        if (state.errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 12),
                            child: Text(state.errorText!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.danger)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const JudulBagian('Berat & tanggal'),
                  TextFormField(
                    key: const Key('field-berat'),
                    controller: _berat,
                    focusNode: _fokusBerat,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      labelText: 'Berat padi',
                      hintText: 'Contoh: 250,5',
                      prefixIcon: Icon(Icons.scale_outlined),
                      suffixText: 'kg',
                    ),
                    validator: PadiMasukValidator.berat,
                  ),
                  const SizedBox(height: 14),
                  // Tanggal otomatis hari ini; ketuk hanya bila perlu diubah
                  FormField<DateTime>(
                    key: const Key('field-tanggal'),
                    initialValue: _tanggal,
                    validator: (_) => PadiMasukValidator.tanggal(_tanggal),
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Hari ini'),
                              selected: _tanggal == hariIni,
                              onSelected: (_) =>
                                  setState(() => _tanggal = hariIni),
                            ),
                            ChoiceChip(
                              label: const Text('Kemarin'),
                              selected: _tanggal == kemarin,
                              onSelected: (_) =>
                                  setState(() => _tanggal = kemarin),
                            ),
                            ChoiceChip(
                              avatar: Icon(Icons.event_rounded,
                                  size: 18,
                                  color: _tanggal != hariIni &&
                                          _tanggal != kemarin
                                      ? Colors.white
                                      : AppColors.textMuted),
                              label: Text(
                                  _tanggal != hariIni && _tanggal != kemarin
                                      ? formatTanggal(_tanggal)
                                      : 'Tanggal lain'),
                              selected:
                                  _tanggal != hariIni && _tanggal != kemarin,
                              onSelected: (_) => _pilihTanggal(),
                            ),
                          ],
                        ),
                        if (state.errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 12),
                            child: Text(state.errorText!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.danger)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    key: const Key('field-catatan'),
                    controller: _catatan,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      hintText: 'Mis. kondisi padi, nomor karung',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                    validator: PadiMasukValidator.catatan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daftar pelanggan yang bisa dicari; menutup dengan id pelanggan terpilih.
class _PilihPelangganSheet extends StatefulWidget {
  final List<Pelanggan> daftar;
  final int? terpilih;

  const _PilihPelangganSheet({required this.daftar, this.terpilih});

  @override
  State<_PilihPelangganSheet> createState() => _PilihPelangganSheetState();
}

class _PilihPelangganSheetState extends State<_PilihPelangganSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final hasil = widget.daftar
        .where((p) =>
            q.isEmpty ||
            p.nama.toLowerCase().contains(q) ||
            p.kontak.contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Pilih pelanggan',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                key: const Key('cari-pelanggan'),
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau no. HP',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Expanded(
              child: hasil.isEmpty
                  ? const KeadaanKosong(
                      icon: Icons.search_off_rounded,
                      judul: 'Pelanggan tidak ditemukan',
                      pesan: 'Tambahkan pelanggan baru di menu Pelanggan.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: hasil.length,
                      itemBuilder: (_, i) {
                        final p = hasil[i];
                        final dipilih = p.id == widget.terpilih;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          leading: CircleAvatar(
                            backgroundColor: p.tipe.latar,
                            foregroundColor: p.tipe.warna,
                            child: Text(p.inisial,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                          ),
                          title: Text(p.nama,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(p.kontak.isEmpty
                              ? p.tipe.label
                              : '${p.tipe.label} · ${p.kontak}'),
                          trailing: dipilih
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.pop(context, p.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
