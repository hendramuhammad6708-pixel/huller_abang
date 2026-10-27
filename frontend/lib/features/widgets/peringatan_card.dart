
import 'package:flutter/material.dart';

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
    this.warna = const Color(0xFF9A6200),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warna.withValues(alpha: 0.25),
        ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: warna,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pesan,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF46566D),
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
