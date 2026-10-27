/// Satu transaksi padi masuk (GET/POST/DELETE /api/padi-masuk).
class PadiMasuk {
  final int? id;
  final DateTime tanggal;
  final int pelangganId;
  final String pelangganNama;
  final int kelasId;
  final String kelasNama;
  final double beratKg;

  /// Catatan bebas; boleh kosong (opsional di backend).
  final String catatan;

  const PadiMasuk({
    this.id,
    required this.tanggal,
    required this.pelangganId,
    this.pelangganNama = '',
    required this.kelasId,
    this.kelasNama = '',
    required this.beratKg,
    this.catatan = '',
  });

  factory PadiMasuk.dariApi(Map<String, dynamic> j) {
    // Nama relasi bisa datar (`nama_pelanggan`) atau bersarang (`pelanggan.nama`)
    final pelanggan = j['pelanggan'];
    final kelas = j['kelas_padi'];
    final berat = j['berat_basah_kg'] ?? j['berat_kg'];

    int? pelangganId = j['pelanggan_id'] as int?;
    if (pelangganId == null && pelanggan is Map) {
      pelangganId = pelanggan['id'] as int?;
    }
    pelangganId ??= 0;

    int? kelasId = j['kelas_padi_id'] as int?;
    if (kelasId == null && kelas is Map) {
      kelasId = kelas['id'] as int?;
    }
    kelasId ??= 0;

    String pelangganNama = (j['nama_pelanggan'] as String?) ??
        (pelanggan is Map ? pelanggan['nama'] as String? : null) ??
        '';
    String kelasNama = (j['nama_kelas'] as String?) ??
        (kelas is Map ? kelas['nama_kelas'] as String? : null) ??
        '';

    final tanggalStr = j['tanggal'] as String?;
    final tanggal = tanggalStr != null ? DateTime.parse(tanggalStr) : DateTime.now();

    return PadiMasuk(
      id: j['id'] as int?,
      tanggal: tanggal,
      pelangganId: pelangganId,
      pelangganNama: pelangganNama,
      kelasId: kelasId,
      kelasNama: kelasNama,
      beratKg: berat is num
          ? berat.toDouble()
          : double.tryParse(berat?.toString() ?? '') ?? 0,
      catatan: (j['catatan'] as String?) ?? '',
    );
  }

  Map<String, dynamic> keApi() => {
        'tanggal': tanggalApi(tanggal),
        'pelanggan_id': pelangganId,
        'kelas_padi_id': kelasId,
        'berat_basah_kg': beratKg,
        'catatan': catatan.isEmpty ? null : catatan,
      };
}

/// Format tanggal untuk API/query: 2026-10-27.
String tanggalApi(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des', //
];

/// Format tanggal tampilan gaya Indonesia: 27 Okt 2026.
String formatTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';
