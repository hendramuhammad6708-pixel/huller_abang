import 'package:flutter/material.dart';

import '../pelanggan/pelanggan_controller.dart';
import '../pengaturan/pengaturan_controller.dart';
import 'padi_masuk_controller.dart';
import 'pages/riwayat_padi_page.dart';

/// Modul penggilingan: catat padi masuk + riwayat berfilter.
/// Halaman ini boleh dibuka operator maupun owner.
class PenggilinganPage extends StatelessWidget {
  final PadiMasukController controller;
  final PelangganController pelanggan;
  final PengaturanController pengaturan;

  const PenggilinganPage({
    super.key,
    required this.controller,
    required this.pelanggan,
    required this.pengaturan,
  });

  @override
  Widget build(BuildContext context) => RiwayatPadiPage(
        controller: controller,
        pelanggan: pelanggan,
        pengaturan: pengaturan,
      );
}
