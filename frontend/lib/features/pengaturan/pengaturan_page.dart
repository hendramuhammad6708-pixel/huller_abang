import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/konfirmasi_hapus.dart';
import '../pelanggan/widgets/format.dart';
import 'pengaturan_controller.dart';

class PengaturanPage extends StatefulWidget {
  final PengaturanController controller;

  const PengaturanPage({super.key, required this.controller});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  static const _contohKg = 825.0;

  final _formKey = GlobalKey<FormState>();
  late final _upah =
      TextEditingController(text: formatPersen(widget.controller.persenUpah));
  late final _operator = TextEditingController(
      text: formatPersen(widget.controller.persenOperator));

  @override
  void initState() {
    super.initState();
    widget.controller.muat().then((_) {
      if (mounted) {
        _upah.text = formatPersen(widget.controller.persenUpah);
        _operator.text = formatPersen(widget.controller.persenOperator);
      }
    });
  }

  @override
  void dispose() {
    _upah.dispose();
    _operator.dispose();
    super.dispose();
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ));
  }

  void _snackGalat(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFD64545),
      ));
  }

  Future<void> _simpanPersen() async {
    if (!_formKey.currentState!.validate()) return;
    final upah = parsePersen(_upah.text)!;
    final operator = parsePersen(_operator.text)!;
    try {
      await widget.controller.simpanPersentase(upah, operator);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      _snack('Pengaturan persentase disimpan');
    } on ApiJawaban catch (e) {
      if (mounted) _snackGalat(e.pesan);
    }
  }

  Future<void> _formKelas([KelasBeras? kelas]) async {
    final nama = await showDialog<String>(
      context: context,
      builder: (_) => _KelasDialog(controller: widget.controller, kelas: kelas),
    );
    if (nama == null || !mounted) return;
    try {
      if (kelas == null) {
        await widget.controller.tambahKelas(nama);
        if (mounted) _snack('Kelas "$nama" ditambahkan');
      } else {
        await widget.controller.ubahKelas(kelas.id, nama);
        if (mounted) _snack('Kelas diubah menjadi "$nama"');
      }
    } on ApiJawaban catch (e) {
      if (mounted) _snackGalat(e.pesan);
    }
  }

  Future<void> _hapusKelas(KelasBeras k) async {
    final ok = await konfirmasiHapus(
      context,
      judul: 'Hapus kelas beras?',
      pesan: 'Kelas "${k.nama}" akan dihapus dari daftar.',
    );
    if (!ok || !mounted) return;
    try {
      await widget.controller.hapusKelas(k.id);
      if (mounted) _snack('Kelas "${k.nama}" dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) _snackGalat(e.pesan);
    }
  }

  InputDecoration _dekor(String label, String hint) => InputDecoration(
        labelText: label,
        helperText: hint,
        suffixText: '%',
        filled: true,
        fillColor: AppColors.background,
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primaryLight, 1.5),
        errorBorder: _border(const Color(0xFFD64545)),
        focusedErrorBorder: _border(const Color(0xFFD64545), 1.5),
      );

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  Widget _kartu({
    required IconData icon,
    required String judul,
    required Widget child,
    Widget? trailing,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.mintText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(judul,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const Text('Pengaturan',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 2),
              const Text('Atur bagi hasil dan jenis beras huller',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 18),
              _kartu(
                icon: Icons.percent_rounded,
                judul: 'Bagi Hasil Penggilingan',
                child: _formPersen(),
              ),
              const SizedBox(height: 16),
              _kartu(
                icon: Icons.grain_rounded,
                judul: 'Kelas / Jenis Beras',
                trailing: TextButton.icon(
                  key: const Key('btn-tambah-kelas'),
                  onPressed: _formKelas,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah'),
                ),
                child: _daftarKelas(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formPersen() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('field-upah'),
            controller: _upah,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: _dekor('Upah huller', 'Dari beras bersih'),
            validator: (v) => validatorPersen(v, 'Upah huller'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('field-operator'),
            controller: _operator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: _dekor('Hak operator', 'Dari upah huller'),
            validator: (v) => validatorPersen(v, 'Hak operator'),
          ),
          const SizedBox(height: 16),
          _preview(),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('btn-simpan-persen'),
            onPressed: _simpanPersen,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Simpan Persentase'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  /// Pratinjau langsung dari angka yang sedang diketik.
  Widget _preview() {
    final u = parsePersen(_upah.text);
    final o = parsePersen(_operator.text);
    final valid = u != null && o != null && u >= 0 && u <= 100 && o >= 0 && o <= 100;
    final h = valid ? BagiHasil.hitung(_contohKg, u, o) : null;

    Widget baris(String label, String nilai, {bool tebal = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              ),
              Text(nilai,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
                    color: tebal ? AppColors.mintText : AppColors.textDark,
                  )),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contoh dari ${formatKg(_contohKg)} beras bersih',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          if (h == null)
            const Text('Isi persentase dengan benar untuk melihat contoh',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted))
          else ...[
            baris('Upah huller', formatKg(h.upahKg)),
            baris('  • Bagian operator', formatKg(h.operatorKg)),
            baris('  • Milik huller', formatKg(h.hullerKg)),
            const Divider(height: 14),
            baris('Masuk saldo pelanggan', formatKg(h.saldoPelangganKg),
                tebal: true),
          ],
        ],
      ),
    );
  }

  Widget _daftarKelas() {
    final kelas = widget.controller.kelas;
    if (kelas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Belum ada kelas beras. Tekan "Tambah" untuk membuat.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return Column(
      children: [
        for (final k in kelas)
          Container(
            key: Key('kelas-${k.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(k.nama,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ),
                IconButton(
                  tooltip: 'Ubah ${k.nama}',
                  onPressed: () => _formKelas(k),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Hapus ${k.nama}',
                  onPressed: () => _hapusKelas(k),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: Color(0xFFD64545)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KelasDialog extends StatefulWidget {
  final PengaturanController controller;
  final KelasBeras? kelas;

  const _KelasDialog({required this.controller, this.kelas});

  @override
  State<_KelasDialog> createState() => _KelasDialogState();
}

class _KelasDialogState extends State<_KelasDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.kelas?.nama);

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  String? _validasi(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Nama kelas wajib diisi';
    // Cek dobel di daftar yang sudah dimuat (backend juga menolak nama dobel)
    final dobel = widget.controller.kelas.any((k) =>
        k.id != widget.kelas?.id &&
        k.nama.toLowerCase() == s.toLowerCase());
    if (dobel) return 'Kelas ini sudah ada';
    return null;
  }

  void _simpan() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _nama.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.kelas == null ? 'Kelas Beras Baru' : 'Ubah Kelas Beras'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('field-kelas'),
          controller: _nama,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama kelas / jenis',
            hintText: 'Contoh: Pandan Wangi',
          ),
          validator: _validasi,
          onFieldSubmitted: (_) => _simpan(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('btn-simpan-kelas'),
          onPressed: _simpan,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
