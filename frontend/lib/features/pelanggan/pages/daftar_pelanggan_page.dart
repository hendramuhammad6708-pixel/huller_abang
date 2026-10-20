import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/konfirmasi_hapus.dart';
import '../models/pelanggan.dart';
import '../pelanggan_controller.dart';
import 'form_pelanggan_page.dart';
import '../widgets/pelanggan_card.dart';
import '../widgets/summary_header.dart';

enum _Filter {
  semua('Semua'),
  petani('Petani'),
  pengepul('Pengepul'),
  milikHuller('Milik Huller');

  final String label;
  const _Filter(this.label);
}

class DaftarPelangganPage extends StatefulWidget {
  final PelangganController controller;

  const DaftarPelangganPage({super.key, required this.controller});

  @override
  State<DaftarPelangganPage> createState() => _DaftarPelangganPageState();
}

class _DaftarPelangganPageState extends State<DaftarPelangganPage> {
  String _query = '';
  _Filter _filter = _Filter.semua;

  @override
  void initState() {
    super.initState();
    widget.controller.muat();
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

  Future<void> _bukaForm([Pelanggan? p]) async {
    final pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPelangganPage(
          controller: widget.controller,
          pelanggan: p,
        ),
      ),
    );
    if (pesan != null && mounted) _snack(pesan);
  }

  Future<void> _hapus(Pelanggan p) async {
    final ok = await konfirmasiHapus(
      context,
      judul: 'Hapus pelanggan?',
      pesan: '${p.nama} akan dihapus dari daftar pelanggan.',
    );
    if (!ok || !mounted) return;
    try {
      await widget.controller.hapus(p.id!);
      if (mounted) _snack('${p.nama} dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) _snack(e.pesan);
    }
  }

  List<Pelanggan> get _hasil {
    final q = _query.trim().toLowerCase();
    return widget.controller.items.where((p) {
      final cocokFilter = switch (_filter) {
        _Filter.semua => true,
        _Filter.petani => p.tipe == TipePelanggan.petani,
        _Filter.pengepul => p.tipe == TipePelanggan.pengepul,
        _Filter.milikHuller => p.tipe == TipePelanggan.milikHuller,
      };
      final cocokCari = q.isEmpty ||
          p.nama.toLowerCase().contains(q) ||
          p.kontak.contains(q);
      return cocokFilter && cocokCari;
    }).toList();
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final c = widget.controller;
    final hasil = _hasil;
    final petani = c.items.where((p) => p.tipe == TipePelanggan.petani).length;
    final pengepul =
        c.items.where((p) => p.tipe == TipePelanggan.pengepul).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-tambah'),
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Pelanggan Baru',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => c.muat(paksa: true),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Daftar Pelanggan',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Kelola data petani & pengepul huller',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 18),
                    if (c.galat != null) ...[
                      _galatBanner(c.galat!, () => c.muat(paksa: true)),
                      const SizedBox(height: 18),
                    ],
                    SummaryHeader(
                      totalPelanggan: c.items.length,
                      totalPetani: petani,
                      totalPengepul: pengepul,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau no. HP',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: _border(AppColors.border),
                        enabledBorder: _border(AppColors.border),
                        focusedBorder: _border(AppColors.primaryLight, 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in _Filter.values) ...[
                            ChoiceChip(
                              label: Text(f.label),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                              showCheckmark: false,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _filter == f
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              if (c.memuat)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasil.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Pelanggan tidak ditemukan',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverList.separated(
                    itemCount: hasil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => PelangganCard(
                      pelanggan: hasil[i],
                      onTap: () => _bukaForm(hasil[i]),
                      onUbah: () => _bukaForm(hasil[i]),
                      onHapus: () => _hapus(hasil[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _galatBanner(String pesan, VoidCallback ulangi) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEAEA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5C2C2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFD64545)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(pesan,
                  style: const TextStyle(color: Color(0xFFD64545))),
            ),
            TextButton(onPressed: ulangi, child: const Text('Ulangi')),
          ],
        ),
      );
}
