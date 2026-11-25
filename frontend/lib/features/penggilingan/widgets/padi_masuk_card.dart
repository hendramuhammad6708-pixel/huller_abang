import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/ui.dart';
import '../../pelanggan/widgets/format.dart';
import '../../widgets/status_badge.dart';
import '../models/padi_masuk.dart';

/// Satu catatan padi masuk. Tanggal tidak ditampilkan di sini karena
/// riwayat sudah dikelompokkan per tanggal.
///
/// Susunan dua baris agar nama, kelas, dan catatan tidak terpotong di layar
/// kecil: baris atas nama + berat, baris bawah status + kelas, lalu catatan.
/// Aksi (cetak, bagikan, batalkan) ada di menu "⋮" supaya tombol batalkan
/// yang berisiko tidak berdempetan dengan aksi yang sering dipakai.
class PadiMasukCard extends StatelessWidget {
  final PadiMasuk padi;
  final VoidCallback onCetak;
  final VoidCallback onBagikan;
  final VoidCallback onVoid;

  const PadiMasukCard({
    super.key,
    required this.padi,
    required this.onCetak,
    required this.onBagikan,
    required this.onVoid,
  });

  /// Transaksi yang sudah selesai giling tidak bisa dibatalkan (ditolak server).
  bool get _bisaBatal =>
      padi.status != 'void' && padi.status != 'selesai_giling';

  @override
  Widget build(BuildContext context) {
    final id = padi.id ?? 0;
    final void_ = padi.status == 'void';

    return KartuApp(
      padding: EdgeInsets.fromLTRB(14, 12, void_ ? 14 : 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IkonKotak(
            Icons.grain_rounded,
            latar: AppColors.goldSoft,
            warna: AppColors.aksen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        padi.pelangganNama.isEmpty ? '-' : padi.pelangganNama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Berat besar (mis. 18.650,75 kg) mengecil, bukan mendesak nama
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatKg(padi.beratKg),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: void_
                                ? AppColors.textMuted
                                : AppColors.primary,
                            decoration: void_
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Status selalu tampil agar operator tahu tahap padi tanpa pindah tab
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (padi.status.isNotEmpty)
                      StatusBadge(key: Key('status-$id'), status: padi.status),
                    if (padi.kelasNama.isNotEmpty)
                      Lencana(
                        padi.kelasNama,
                        latar: AppColors.goldSoft,
                        warna: AppColors.gold,
                      ),
                  ],
                ),
                if (padi.catatan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    padi.catatan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!void_)
            PopupMenuButton<_Aksi>(
              key: Key('btn-menu-$id'),
              tooltip: 'Aksi',
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textMuted,
              ),
              onSelected: (aksi) => switch (aksi) {
                _Aksi.cetak => onCetak(),
                _Aksi.bagikan => onBagikan(),
                _Aksi.batal => onVoid(),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  key: Key('btn-cetak-$id'),
                  value: _Aksi.cetak,
                  child: const _IsiMenu(Icons.print_outlined, 'Cetak struk'),
                ),
                PopupMenuItem(
                  key: Key('btn-bagikan-$id'),
                  value: _Aksi.bagikan,
                  child: const _IsiMenu(
                    Icons.share_outlined,
                    'Bagikan via WhatsApp',
                  ),
                ),
                if (_bisaBatal) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    key: Key('btn-void-$id'),
                    value: _Aksi.batal,
                    child: const _IsiMenu(
                      Icons.cancel_outlined,
                      'Batalkan (Void)',
                      warna: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

enum _Aksi { cetak, bagikan, batal }

class _IsiMenu extends StatelessWidget {
  final IconData ikon;
  final String label;
  final Color warna;

  const _IsiMenu(this.ikon, this.label, {this.warna = AppColors.textDark});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(ikon, size: 20, color: warna),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          label,
          style: TextStyle(color: warna, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
