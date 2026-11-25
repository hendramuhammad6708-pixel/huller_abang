import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/konfirmasi_hapus.dart';
import '../../../core/ui.dart';
import '../../penggilingan/models/padi_masuk.dart';
import '../models/pelanggan.dart';
import '../pelanggan_controller.dart';
import '../riwayat_transaksi_controller.dart';
import '../widgets/format.dart';
import 'form_pelanggan_page.dart';

/// Detail satu pelanggan: profil, status transaksi terakhir, dan riwayat padi
/// masuknya. Menutup halaman dengan pesan sukses (ubah/hapus) untuk daftar.
class DetailPelangganPage extends StatefulWidget {
  final Pelanggan pelanggan;
  final PelangganController pelangganController;
  final RiwayatTransaksiController riwayatController;

  const DetailPelangganPage({
    super.key,
    required this.pelanggan,
    required this.pelangganController,
    required this.riwayatController,
  });

  @override
  State<DetailPelangganPage> createState() => _DetailPelangganPageState();
}

class _DetailPelangganPageState extends State<DetailPelangganPage> {
  @override
  void initState() {
    super.initState();
    widget.riwayatController.muat();
  }

  Future<void> _ubah() async {
    final pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPelangganPage(
          controller: widget.pelangganController,
          pelanggan: widget.pelanggan,
        ),
      ),
    );
    // Data berubah/terhapus: kembali ke daftar yang sudah dimuat ulang
    if (pesan != null && mounted) Navigator.pop(context, pesan);
  }

  Future<void> _hapus() async {
    final p = widget.pelanggan;
    final id = p.id;
    if (id == null) return;
    final ok = await konfirmasiHapus(
      context,
      judul: 'Hapus pelanggan?',
      pesan:
          '${p.nama} akan dihapus dari daftar pelanggan. '
          'Riwayat transaksinya tetap tersimpan.',
    );
    if (!ok || !mounted) return;
    try {
      await widget.pelangganController.hapus(id);
      if (mounted) Navigator.pop(context, '${p.nama} dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) tampilkanPesan(context, e.pesan, galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        actions: [
          IconButton(
            key: const Key('btn-ubah-pelanggan'),
            tooltip: 'Ubah pelanggan',
            onPressed: _ubah,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: const Key('btn-hapus-pelanggan'),
            tooltip: 'Hapus pelanggan',
            onPressed: _hapus,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.riwayatController,
        builder: (context, _) => LayoutBuilder(
          builder: (context, batas) =>
              _isi(context, jarakSamping(batas.maxWidth)),
        ),
      ),
    );
  }

  Widget _isi(BuildContext context, double samping) {
    final p = widget.pelanggan;
    final r = widget.riwayatController;

    return RefreshIndicator(
      onRefresh: () => r.muat(paksa: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(samping, 8, samping, 32),
        children: [
          _profil(p, r),
          const SizedBox(height: 20),
          JudulBagian(
            'Riwayat transaksi',
            aksi: Text(
              '${r.total} transaksi',
              key: const Key('riwayat-total-transaksi'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (r.galat != null) ...[
            BannerGalat(r.galat!, onUlangi: () => r.muat(paksa: true)),
            const SizedBox(height: 12),
          ],
          if (r.memuat && r.items.isEmpty)
            const Column(
              children: [
                SkeletonKartu(baris: 2),
                SizedBox(height: 10),
                SkeletonKartu(baris: 2),
              ],
            )
          else if (r.items.isEmpty && r.galat == null)
            const KeadaanKosong(
              icon: Icons.grain_rounded,
              judul: 'Belum ada transaksi',
              pesan: 'Padi masuk milik pelanggan ini akan muncul di sini.',
            )
          else
            for (final padi in r.items) ...[
              _BarisTransaksi(padi: padi),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _profil(Pelanggan p, RiwayatTransaksiController r) {
    return KartuApp(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.mint,
            child: Text(
              p.inisial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mintText,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Lencana(p.tipe.label),
                    if (p.kontak.isNotEmpty)
                      Text(
                        p.kontak,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formatTerakhir(
                    r.tanggalTerakhir,
                    status: r.statusTerakhir ?? '',
                    statusLabel: r.statusTerakhirLabel ?? '',
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu transaksi di riwayat pelanggan: tanggal, kelas, status, dan berat.
class _BarisTransaksi extends StatelessWidget {
  final PadiMasuk padi;

  const _BarisTransaksi({required this.padi});

  @override
  Widget build(BuildContext context) {
    final void_ = padi.status == 'void';
    final (latar, warna) = switch (padi.status) {
      'void' => (AppColors.dangerSoft, AppColors.danger),
      'dijemur' || 'masuk' => (AppColors.goldSoft, AppColors.gold),
      _ => (AppColors.mint, AppColors.mintText),
    };

    return KartuApp(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTanggal(padi.tanggal),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (padi.kelasNama.isNotEmpty)
                      Lencana(
                        padi.kelasNama,
                        latar: AppColors.goldSoft,
                        warna: AppColors.gold,
                      ),
                    if (padi.statusLabel.isNotEmpty)
                      Lencana(padi.statusLabel, latar: latar, warna: warna),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatKg(padi.beratKg),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: void_ ? AppColors.textMuted : AppColors.primary,
                  decoration: void_ ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
