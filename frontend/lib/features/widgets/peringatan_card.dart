import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class PeringatanCard extends StatelessWidget {
  final String judul;
  final String pesan;
  final IconData ikon;
  final Color warna;

  const PeringatanCard({
    super.key,
    required this.judul,
    required this.pesan,
    this.ikon = Icons.info_outline_rounded,
    this.warna = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sedang),
        border: Border.all(color: warna.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: warna, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: TextStyle(fontWeight: FontWeight.w800, color: warna),
                ),
                const SizedBox(height: 4),
                Text(
                  pesan,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
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
