/// Status otomatis: Masuk -> Dijemur -> Siap Giling
enum StatusPenjemuran { masuk, dijemur, siapGiling }

StatusPenjemuran _parseStatus(String? s) {
  switch ((s ?? '').toLowerCase().replaceAll('_', ' ')) {
    case 'dijemur':
      return StatusPenjemuran.dijemur;
    case 'siap giling':
      return StatusPenjemuran.siapGiling;
    default:
      return StatusPenjemuran.masuk;
  }
}

String labelStatus(StatusPenjemuran s) => switch (s) {
  StatusPenjemuran.masuk => 'Masuk',
  StatusPenjemuran.dijemur => 'Dijemur',
  StatusPenjemuran.siapGiling => 'Siap Giling',
};

class Penjemuran {
  final int id;
  final String pelanggan;
  final String kelas;
  final DateTime tanggalMasuk;
  final double beratBasah;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final double? beratKering;
  final StatusPenjemuran status;

  Penjemuran({
    required this.id,
    required this.pelanggan,
    required this.kelas,
    required this.tanggalMasuk,
    required this.beratBasah,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.beratKering,
    required this.status,
  });

  factory Penjemuran.fromJson(Map<String, dynamic> j) {
    DateTime? tgl(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    double? num_(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().replaceAll(',', '.');
      return double.tryParse(s);
    }

    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final tanggalMasukStr = j['tanggal_masuk']?.toString();
    DateTime tanggalMasuk = DateTime.now();
    if (tanggalMasukStr != null && tanggalMasukStr.isNotEmpty) {
      try {
        tanggalMasuk = DateTime.parse(tanggalMasukStr);
      } catch (_) {}
    }

    return Penjemuran(
      id: parseId(j['id']),
      pelanggan: (j['pelanggan'] ?? '-').toString(),
      kelas: (j['kelas'] ?? '-').toString(),
      tanggalMasuk: tanggalMasuk,
      beratBasah: num_(j['berat_basah']) ?? 0,
      tanggalMulai: tgl(j['tanggal_mulai']),
      tanggalSelesai: tgl(j['tanggal_selesai']),
      beratKering: num_(j['berat_kering']),
      status: _parseStatus(j['status']?.toString()),
    );
  }

  /// Durasi jemur dalam hari (berjalan sampai hari ini bila belum selesai).
  int? get durasiHari {
    if (tanggalMulai == null) return null;
    final akhir = tanggalSelesai ?? DateTime.now();
    final a = DateTime(tanggalMulai!.year, tanggalMulai!.month, tanggalMulai!.day);
    final b = DateTime(akhir.year, akhir.month, akhir.day);
    return b.difference(a).inDays;
  }

  /// Persen susut = (basah - kering) / basah x 100
  double? get persenSusut => hitungSusut(beratBasah, beratKering);
}

double? hitungSusut(double basah, double? kering) =>
    (basah > 0 && kering != null) ? (basah - kering) / basah * 100 : null;