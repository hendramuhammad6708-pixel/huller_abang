import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Placeholder modul penggilingan — dikerjakan Sprint 2 (transaksi padi masuk).
/// Halaman ini boleh dibuka operator maupun owner.
class PenggilinganPage extends StatelessWidget {
  const PenggilinganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text(
              'Penggilingan',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            const Text('Catat padi masuk & hasil bagi hasil',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.grain_rounded, size: 56, color: AppColors.mintText),
                  SizedBox(height: 16),
                  Text(
                    'Modul Penggilingan\nSegera Hadir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Transaksi padi masuk, pembagian upah,\n'
                    'dan saldo beras pelanggan akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
