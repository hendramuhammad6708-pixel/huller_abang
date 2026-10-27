import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../pelanggan/widgets/format.dart';
import '../models/padi_masuk.dart';

class PadiMasukCard extends StatelessWidget {
  final PadiMasuk padi;
  final VoidCallback onHapus;

  const PadiMasukCard({super.key, required this.padi, required this.onHapus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.grain_rounded, color: AppColors.mintText),
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatTanggal(padi.tanggal)}'
                  '${padi.kelasNama.isEmpty ? '' : ' · ${padi.kelasNama}'}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
                if (padi.catatan.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    padi.catatan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatKg(padi.beratKg),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.mintText,
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Color(0xFFD64545)),
          ),
        ],
      ),
    );
  }
}
