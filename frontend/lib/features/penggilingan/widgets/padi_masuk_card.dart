import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/ui.dart';
import '../../pelanggan/widgets/format.dart';
import '../models/padi_masuk.dart';

/// Satu catatan padi masuk. Tanggal tidak ditampilkan di sini karena
/// riwayat sudah dikelompokkan per tanggal.
class PadiMasukCard extends StatelessWidget {
  final PadiMasuk padi;
  final VoidCallback onHapus;

  const PadiMasukCard({super.key, required this.padi, required this.onHapus});

  @override
  Widget build(BuildContext context) {
    return KartuApp(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          const IkonKotak(Icons.grain_rounded,
              latar: AppColors.goldSoft, warna: AppColors.aksen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  padi.pelangganNama.isEmpty ? '-' : padi.pelangganNama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (padi.kelasNama.isNotEmpty) ...[
                      Flexible(
                        child: Lencana(padi.kelasNama,
                            latar: AppColors.goldSoft, warna: AppColors.gold),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (padi.catatan.isNotEmpty)
                      Expanded(
                        child: Text(
                          padi.catatan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Berat besar (mis. 18.650,75 kg) mengecil, bukan mendesak nama
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatKg(padi.beratKg),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hapus catatan',
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
