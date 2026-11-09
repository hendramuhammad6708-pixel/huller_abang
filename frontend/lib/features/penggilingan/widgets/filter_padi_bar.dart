import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../pelanggan/models/pelanggan.dart';
import '../../pengaturan/pengaturan_controller.dart';
import '../models/padi_masuk.dart';
import '../padi_masuk_controller.dart';

/// Pilihan cepat rentang tanggal.
enum _Rentang {
  hariIni('Hari ini'),
  tujuhHari('7 hari'),
  bulanIni('Bulan ini');

  final String label;
  const _Rentang(this.label);

  DateTimeRange get nilai {
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    return switch (this) {
      _Rentang.hariIni => DateTimeRange(start: hariIni, end: hariIni),
      _Rentang.tujuhHari => DateTimeRange(
          start: hariIni.subtract(const Duration(days: 6)), end: hariIni),
      _Rentang.bulanIni =>
        DateTimeRange(start: DateTime(n.year, n.month), end: hariIni),
    };
  }
}

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

  Widget _dropdown({
    required Key key,
    required IconData icon,
    required String hint,
    required int? nilai,
    required List<(int, String)> pilihan,
    required ValueChanged<int?> onChanged,
  }) {
    // Nilai yang sudah tidak ada di daftar (mis. data dihapus) dianggap kosong
    final ada = pilihan.any((p) => p.$1 == nilai);
    final aktif = ada && nilai != null;
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: aktif ? AppColors.mint.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sedang),
        border: Border.all(
            color: aktif ? AppColors.primaryLight : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: aktif ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                key: key,
                isExpanded: true,
                value: ada ? nilai : null,
                hint: Text(hint, overflow: TextOverflow.ellipsis),
                borderRadius: BorderRadius.circular(AppRadius.sedang),
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = controller.rentang;
    final preset = _Rentang.values.where((p) => p.nilai == r).firstOrNull;
    final rentangKhusus = r != null && preset == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: r == null,
                onSelected: (_) => controller.setFilter(hapusRentang: true),
              ),
              for (final p in _Rentang.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(p.label),
                  selected: preset == p,
                  onSelected: (_) => controller.setFilter(rentang: p.nilai),
                ),
              ],
              const SizedBox(width: 8),
              ChoiceChip(
                key: const Key('filter-tanggal'),
                avatar: Icon(Icons.date_range_rounded,
                    size: 18,
                    color: rentangKhusus ? Colors.white : AppColors.textMuted),
                label: Text(rentangKhusus
                    ? '${formatTanggal(r.start)} – ${formatTanggal(r.end)}'
                    : 'Pilih tanggal'),
                selected: rentangKhusus,
                onSelected: (_) => _pilihTanggal(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dropdown(
                key: const Key('filter-pelanggan'),
                icon: Icons.person_outline_rounded,
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
                icon: Icons.category_outlined,
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
              label: const Text('Hapus semua filter'),
            ),
          ),
      ],
    );
  }
}
