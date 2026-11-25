import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Lencana status padi masuk / penjemuran.
///
/// Menerima nilai status mentah dari API (`masuk`, `dijemur`, `siap_giling`,
/// `selesai_giling`, `void`)
/// dan memetakan sendiri ke warna serta label. Dipakai bersama oleh halaman
/// penjemuran dan kartu padi masuk.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final nilai = status.trim().toLowerCase();
    final (latar, warna, ikon, label) = switch (nilai) {
      'masuk' => (
        AppColors.blueSoft,
        AppColors.blue,
        Icons.inventory_2_rounded,
        'Masuk',
      ),
      'dijemur' => (
        AppColors.goldSoft,
        AppColors.gold,
        Icons.wb_sunny_rounded,
        'Dijemur',
      ),
      'siap_giling' => (
        AppColors.mint,
        AppColors.mintText,
        Icons.check_circle_rounded,
        'Siap Giling',
      ),
      'selesai_giling' => (
        AppColors.mint,
        AppColors.primaryDark,
        Icons.task_alt_rounded,
        'Selesai Giling',
      ),
      'void' => (
        AppColors.dangerSoft,
        AppColors.danger,
        Icons.cancel_rounded,
        'VOID',
      ),
      _ => (
        AppColors.background,
        AppColors.textMuted,
        Icons.schedule_rounded,
        nilai.isEmpty ? 'Menunggu' : nilai,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: warna),
          const SizedBox(width: 5),
          // Flexible: di baris sempit label mengecil dengan "…", bukan overflow
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: warna,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
