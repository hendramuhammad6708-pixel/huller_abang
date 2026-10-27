import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/konfirmasi_hapus.dart';
import '../../pelanggan/pelanggan_controller.dart';
import '../../pelanggan/widgets/format.dart';
import '../../pengaturan/pengaturan_controller.dart';
import '../models/padi_masuk.dart';
import '../padi_masuk_controller.dart';
import '../widgets/filter_padi_bar.dart';
import '../widgets/padi_masuk_card.dart';
import 'form_padi_masuk_page.dart';

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

  void _snack(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ));
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
    if (pesan != null && mounted) _snack(pesan);
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
      if (mounted) _snack('Catatan dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) _snack(e.pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [widget.controller, widget.pelanggan, widget.pengaturan]),
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final c = widget.controller;
    final items = c.items;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-padi-masuk'),
        onPressed: _bukaForm,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Padi',
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
                      'Padi Masuk',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Riwayat padi masuk',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 18),
                    if (c.galat != null) ...[
                      _galatBanner(c.galat!, () => c.muat(paksa: true)),
                      const SizedBox(height: 18),
                    ],
                    FilterPadiBar(
                      controller: c,
                      pelanggan: widget.pelanggan.items,
                      kelas: widget.pengaturan.kelas,
                    ),
                    const SizedBox(height: 12),
                    _ringkasan(items.length, c.totalKg),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              if (c.memuat)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      c.adaFilter
                          ? 'Tidak ada catatan untuk filter ini'
                          : 'Belum ada padi masuk',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => PadiMasukCard(
                      padi: items[i],
                      onHapus: () => _hapus(items[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ringkasan(int jumlah, double totalKg) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.grain_rounded, color: AppColors.mintText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$jumlah transaksi',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.mintText),
              ),
            ),
            Text(
              formatKg(totalKg),
              key: const Key('total-kg'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );

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
