import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/ui.dart';
import '../models/pelanggan.dart';

/// Warna avatar & lencana per tipe pelanggan.
extension WarnaTipe on TipePelanggan {
  Color get latar => switch (this) {
    TipePelanggan.pengepul => AppColors.blueSoft,
    TipePelanggan.milikHuller => AppColors.goldSoft,
    TipePelanggan.petani => AppColors.mint,
  };

  Color get warna => switch (this) {
    TipePelanggan.pengepul => AppColors.blue,
    TipePelanggan.milikHuller => AppColors.gold,
    TipePelanggan.petani => AppColors.mintText,
  };
}

class PelangganCard extends StatelessWidget {
  final Pelanggan pelanggan;
  final VoidCallback? onTap;

  const PelangganCard({super.key, required this.pelanggan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pelanggan;

    return KartuApp(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.tipe.latar,
              borderRadius: BorderRadius.circular(AppRadius.sedang),
            ),
            child: Text(
              p.inisial,
              style: TextStyle(
                color: p.tipe.warna,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Lencana(
                      p.tipe.label,
                      latar: p.tipe.latar,
                      warna: p.tipe.warna,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        p.kontak.isEmpty ? 'Tanpa no. HP' : p.kontak,
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
