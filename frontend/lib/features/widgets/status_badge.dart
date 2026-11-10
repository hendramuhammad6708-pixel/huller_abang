
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final teks = status.trim().toLowerCase();

    Color warnaLatar;
    Color warnaTeks;
    IconData ikon;

    switch (teks) {
      case 'masuk':
        warnaLatar = const Color(0xFFE8EDF5);
        warnaTeks = const Color(0xFF46566D);
        ikon = Icons.inventory_2_outlined;
        break;

      case 'selesai':
      case 'siap giling':
        warnaLatar = const Color(0xFFE0F5E9);
        warnaTeks = const Color(0xFF16834A);
        ikon = Icons.check_circle_outline;
        break;

      case 'diproses':
      case 'dijemur':
        warnaLatar = const Color(0xFFFFF0D6);
        warnaTeks = const Color(0xFF9A6200);
        ikon = Icons.autorenew_rounded;
        break;

      case 'dibatalkan':
      case 'gagal':
        warnaLatar = const Color(0xFFFFE4E4);
        warnaTeks = const Color(0xFFC62828);
        ikon = Icons.cancel_outlined;
        break;

      default:
        warnaLatar = const Color(0xFFE8EDF5);
        warnaTeks = const Color(0xFF46566D);
        ikon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 15, color: warnaTeks),
          const SizedBox(width: 5),
          Text(
            status.isEmpty ? 'Menunggu' : status,
            style: TextStyle(
              color: warnaTeks,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
