import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/konfirmasi_hapus.dart';
import '../../../core/ui.dart';
import '../../pelanggan/pelanggan_controller.dart';
import '../../pelanggan/widgets/format.dart';
import '../../pengaturan/pengaturan_controller.dart';
import '../models/padi_masuk.dart';
import '../padi_masuk_controller.dart';
import '../widgets/filter_padi_bar.dart';
import '../widgets/padi_masuk_card.dart';
import 'form_padi_masuk_page.dart';

/// Judul kelompok tanggal di riwayat beserta subtotalnya.
class _Kelompok {
  final DateTime tanggal;
  final double totalKg;
  const _Kelompok(this.tanggal, this.totalKg);
}

/// Riwayat padi masuk dengan filter tanggal/pelanggan/kelas dan tombol catat baru.
class RiwayatPadiPage extends StatefulWidget {
  final PadiMasukController controller;
  final PelangganController pelanggan;
  final PengaturanController pengaturan;

  const RiwayatPadiPage({
    super.key,
    required this.controller,
    required this.pelanggan,
    required this.pengaturan,
  });

  @override
  State<RiwayatPadiPage> createState() => _RiwayatPadiPageState();
}

class _RiwayatPadiPageState extends State<RiwayatPadiPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.muat();
    widget.pelanggan.muat();
    widget.pengaturan.muat();
  }

  Future<void> _bukaForm() async {
    final pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPadiMasukPage(
          controller: widget.controller,
          pelanggan: widget.pelanggan,
          pengaturan: widget.pengaturan,
        ),
      ),
    );
    if (pesan != null && mounted) tampilkanPesan(context, pesan);
  }

  Future<void> _hapus(PadiMasuk p) async {
    final ok = await konfirmasiHapus(
      context,
      judul: 'Hapus catatan?',
      pesan: 'Padi masuk ${p.pelangganNama} '
          '(${formatKg(p.beratKg)}, ${formatTanggal(p.tanggal)}) akan dihapus.',
    );
    if (!ok || !mounted) return;
    try {
      await widget.controller.hapus(p.id!);
      if (mounted) tampilkanPesan(context, 'Catatan dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) tampilkanPesan(context, e.pesan, galat: true);
    }
  }

  /// Sisipkan judul tanggal di antara catatan (daftar sudah urut dari API).
  List<Object> _kelompokkan(List<PadiMasuk> items) {
    final hasil = <Object>[];
    for (var i = 0; i < items.length; i++) {
      final t = items[i].tanggal;
      if (i == 0 || !_hariSama(items[i - 1].tanggal, t)) {
        final total = items
            .where((e) => _hariSama(e.tanggal, t))
            .fold<double>(0, (j, e) => j + e.beratKg);
        hasil.add(_Kelompok(t, total));
      }
      hasil.add(items[i]);
    }
    return hasil;
  }

  bool _hariSama(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _labelTanggal(DateTime t) {
    final n = DateTime.now();
    if (_hariSama(t, n)) return 'Hari ini';
    if (_hariSama(t, n.subtract(const Duration(days: 1)))) return 'Kemarin';
    return formatTanggal(t);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [widget.controller, widget.pelanggan, widget.pengaturan]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, batas) =>
            _buildPage(context, jarakSamping(batas.maxWidth)),
      ),
    );
  }

  Widget _buildPage(BuildContext context, double samping) {
    final c = widget.controller;
    final items = c.items;
    final baris = _kelompokkan(items);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-padi-masuk'),
        onPressed: _bukaForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Padi'),
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
                  _ringkasan(items.length, c.totalKg, c.adaFilter),
                  const SizedBox(height: 16),
                  FilterPadiBar(
                    controller: c,
                    pelanggan: widget.pelanggan.items,
                    kelas: widget.pengaturan.kelas,
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
            if (c.memuat && items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: c.adaFilter
                    ? KeadaanKosong(
                        icon: Icons.filter_alt_off_rounded,
                        judul: 'Tidak ada catatan',
                        pesan: 'Tidak ada padi masuk untuk filter ini.',
                        labelAksi: 'Hapus filter',
                        ikonAksi: Icons.filter_alt_off_rounded,
                        onAksi: c.resetFilter,
                      )
                    : KeadaanKosong(
                        icon: Icons.grain_rounded,
                        judul: 'Belum ada padi masuk',
                        pesan: 'Catat setiap padi yang datang agar riwayat '
                            'dan bagi hasil tercatat rapi.',
                        labelAksi: 'Catat padi masuk',
                        onAksi: _bukaForm,
                      ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(samping, 0, samping, 96),
                sliver: SliverList.builder(
                  itemCount: baris.length,
                  itemBuilder: (_, i) => switch (baris[i]) {
                    final _Kelompok k => _judulTanggal(k),
                    final PadiMasuk p => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PadiMasukCard(
                            padi: p, onHapus: () => _hapus(p)),
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _judulTanggal(_Kelompok k) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(_labelTanggal(k.tanggal),
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ),
            Text(formatKg(k.totalKg),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _ringkasan(int jumlah, double totalKg, bool adaFilter) => PanelHero(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adaFilter ? 'Total padi masuk (terfilter)' : 'Total padi masuk',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatKg(totalKg),
                      key: const Key('total-kg'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.aksen,
                borderRadius: BorderRadius.circular(AppRadius.sedang),
              ),
              child: Column(
                children: [
                  Text('$jumlah',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark)),
                  const Text('transaksi',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark)),
                ],
              ),
            ),
          ],
        ),
      );
}
