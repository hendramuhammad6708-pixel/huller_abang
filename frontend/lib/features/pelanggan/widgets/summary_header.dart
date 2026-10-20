import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class SummaryHeader extends StatelessWidget {
  final int totalPelanggan;
  final int totalPetani;
  final int totalPengepul;

  const SummaryHeader({
    super.key,
    required this.totalPelanggan,
    required this.totalPetani,
    required this.totalPengepul,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Item(
              icon: Icons.groups_rounded,
              label: 'Total Pelanggan',
              value: '$totalPelanggan',
            ),
          ),
          Container(width: 1, height: 44, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: _Item(
              icon: Icons.grass_rounded,
              label: 'Petani / Pengepul',
              value: '$totalPetani / $totalPengepul',
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Item({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.white70),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
