import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/ui.dart';
import '../../pelanggan/widgets/format.dart';
import '../models/padi_masuk.dart';

/// Satu catatan padi masuk. Tanggal tidak ditampilkan di sini karena
/// riwayat sudah dikelompokkan per tanggal.
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

  @override
  Widget build(BuildContext context) {
    return KartuApp(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
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
                        child: Lencana(
                          padi.kelasNama,
                          latar: AppColors.goldSoft,
                          warna: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (padi.status == 'void' ||
                        padi.status == 'selesai_giling') ...[
                      Lencana(
                        padi.statusLabel.isEmpty
                            ? padi.status.toUpperCase()
                            : padi.statusLabel,
                        key: Key('status-${padi.id ?? 0}'),
                        latar: padi.status == 'void'
                            ? AppColors.dangerSoft
                            : AppColors.mint,
                        warna: padi.status == 'void'
                            ? AppColors.danger
                            : AppColors.mintText,
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
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
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
          if (padi.status != 'void') ...[
            IconButton(
              key: Key('btn-cetak-${padi.id ?? 0}'),
              tooltip: 'Cetak',
              onPressed: onCetak,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              icon: const Icon(
                Icons.print_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
            IconButton(
              key: Key('btn-bagikan-${padi.id ?? 0}'),
              tooltip: 'Bagikan via WhatsApp',
              onPressed: onBagikan,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              icon: const Icon(
                Icons.share_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (padi.status != 'void')
            IconButton(
              key: Key('btn-void-${padi.id ?? 0}'),
              tooltip: 'Batalkan (Void)',
              onPressed: onVoid,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              icon: const Icon(
                Icons.cancel_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
