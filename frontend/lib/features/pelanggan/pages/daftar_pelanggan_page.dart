import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/konfirmasi_hapus.dart';
import '../../../core/ui.dart';
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

  bool cocok(Pelanggan p) => switch (this) {
        _Filter.semua => true,
        _Filter.petani => p.tipe == TipePelanggan.petani,
        _Filter.pengepul => p.tipe == TipePelanggan.pengepul,
        _Filter.milikHuller => p.tipe == TipePelanggan.milikHuller,
      };
}

class DaftarPelangganPage extends StatefulWidget {
  final PelangganController controller;

  const DaftarPelangganPage({super.key, required this.controller});

  @override
  State<DaftarPelangganPage> createState() => _DaftarPelangganPageState();
}

class _DaftarPelangganPageState extends State<DaftarPelangganPage> {
  final _cari = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.semua;

  @override
  void initState() {
    super.initState();
    widget.controller.muat();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
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
    if (pesan != null && mounted) tampilkanPesan(context, pesan);
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
      if (mounted) tampilkanPesan(context, '${p.nama} dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) tampilkanPesan(context, e.pesan, galat: true);
    }
  }

  void _bersihkanCari() {
    _cari.clear();
    setState(() => _query = '');
  }

  List<Pelanggan> get _hasil {
    final q = _query.trim().toLowerCase();
    return widget.controller.items.where((p) {
      final cocokCari = q.isEmpty ||
          p.nama.toLowerCase().contains(q) ||
          p.kontak.contains(q);
      return _filter.cocok(p) && cocokCari;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, batas) =>
            _buildPage(context, jarakSamping(batas.maxWidth)),
      ),
    );
  }

  Widget _buildPage(BuildContext context, double samping) {
    final c = widget.controller;
    final hasil = _hasil;
    final petani = c.items.where(_Filter.petani.cocok).length;
    final pengepul = c.items.where(_Filter.pengepul.cocok).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-tambah'),
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Pelanggan Baru'),
      ),
      body: RefreshIndicator(
        onRefresh: () => c.muat(paksa: true),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(samping, 4, samping, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (c.galat != null) ...[
                    BannerGalat(c.galat!, onUlangi: () => c.muat(paksa: true)),
                    const SizedBox(height: 16),
                  ],
                  SummaryHeader(
                    totalPelanggan: c.items.length,
                    totalPetani: petani,
                    totalPengepul: pengepul,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cari,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau no. HP',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: _bersihkanCari,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _Filter.values) ...[
                          ChoiceChip(
                            label: Text(
                                '${f.label} (${c.items.where(f.cocok).length})'),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
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
            if (c.memuat && c.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (hasil.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: c.items.isEmpty
                    ? KeadaanKosong(
                        icon: Icons.groups_rounded,
                        judul: 'Belum ada pelanggan',
                        pesan:
                            'Tambahkan petani atau pengepul yang menggiling di huller.',
                        labelAksi: 'Tambah pelanggan',
                        onAksi: () => _bukaForm(),
                      )
                    : const KeadaanKosong(
                        icon: Icons.search_off_rounded,
                        judul: 'Pelanggan tidak ditemukan',
                        pesan: 'Coba kata kunci lain atau ubah filter tipe.',
                      ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(samping, 0, samping, 96),
                sliver: SliverList.separated(
                  itemCount: hasil.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    );
  }
}
