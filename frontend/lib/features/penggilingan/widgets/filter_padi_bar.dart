import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../pelanggan/models/pelanggan.dart';
import '../../pengaturan/pengaturan_controller.dart';
import '../models/padi_masuk.dart';
import '../padi_masuk_controller.dart';

/// Filter riwayat: rentang tanggal, pelanggan, dan kelas padi.
class FilterPadiBar extends StatelessWidget {
  final PadiMasukController controller;
  final List<Pelanggan> pelanggan;
  final List<KelasBeras> kelas;

  const FilterPadiBar({
    super.key,
    required this.controller,
    required this.pelanggan,
    required this.kelas,
  });

  Future<void> _pilihTanggal(BuildContext context) async {
    final sekarang = DateTime.now();
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(sekarang.year - 5),
      lastDate: DateTime(sekarang.year, sekarang.month, sekarang.day),
      initialDateRange: controller.rentang,
      helpText: 'Pilih rentang tanggal',
    );
    if (hasil != null) controller.setFilter(rentang: hasil);
  }

  BoxDecoration get _kotak => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      );

  Widget _dropdown({
    required Key key,
    required String hint,
    required int? nilai,
    required List<(int, String)> pilihan,
    required ValueChanged<int?> onChanged,
  }) {
    // Nilai yang sudah tidak ada di daftar (mis. data dihapus) dianggap kosong
    final ada = pilihan.any((p) => p.$1 == nilai);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _kotak,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          key: key,
          isExpanded: true,
          value: ada ? nilai : null,
          hint: Text(hint),
          borderRadius: BorderRadius.circular(16),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(hint)),
            for (final p in pilihan)
              DropdownMenuItem<int?>(
                value: p.$1,
                child: Text(p.$2, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = controller.rentang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                key: const Key('filter-tanggal'),
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pilihTanggal(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: _kotak,
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded,
                          size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r == null
                              ? 'Semua tanggal'
                              : '${formatTanggal(r.start)} – ${formatTanggal(r.end)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (r != null)
                        InkWell(
                          onTap: () => controller.setFilter(hapusRentang: true),
                          child: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dropdown(
                key: const Key('filter-pelanggan'),
                hint: 'Semua pelanggan',
                nilai: controller.pelangganId,
                pilihan: [
                  for (final p in pelanggan)
                    if (p.id != null) (p.id!, p.nama),
                ],
                onChanged: (v) => v == null
                    ? controller.setFilter(hapusPelanggan: true)
                    : controller.setFilter(pelangganId: v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dropdown(
                key: const Key('filter-kelas'),
                hint: 'Semua kelas',
                nilai: controller.kelasId,
                pilihan: [for (final k in kelas) (k.id, k.nama)],
                onChanged: (v) => v == null
                    ? controller.setFilter(hapusKelas: true)
                    : controller.setFilter(kelasId: v),
              ),
            ),
          ],
        ),
        if (controller.adaFilter)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('filter-reset'),
              onPressed: controller.resetFilter,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Reset filter'),
            ),
          ),
      ],
    );
  }
}
