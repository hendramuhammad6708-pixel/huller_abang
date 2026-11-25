const int batasDurasiTerlaluLama = 3;

/// Penjemuran baru boleh diselesaikan setelah minimal sekian hari sejak
/// tanggal mulai (backend menolak yang kurang: PadiMasukService::MIN_JEMUR_HARI).
const int minHariJemur = 2;

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

/// Nilai status sesuai konstanta API (`masuk`, `dijemur`, `siap_giling`).
String nilaiApi(StatusPenjemuran s) => switch (s) {
  StatusPenjemuran.masuk => 'masuk',
  StatusPenjemuran.dijemur => 'dijemur',
  StatusPenjemuran.siapGiling => 'siap_giling',
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

  // Dihitung server (zona waktu huller, bukan jam HP). Null bila server lama
  // belum mengirimnya; getter di bawah lalu menghitung sendiri.
  final int? _durasiServer;
  final bool? _terlaluLamaServer;
  final double? _persenSusutServer;
  final bool? _bolehDiselesaikanServer;
  final DateTime? _palingCepatSelesaiServer;

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
    int? durasiHari,
    bool? terlaluLama,
    double? persenSusut,
    bool? bolehDiselesaikan,
    DateTime? tanggalPalingCepatSelesai,
  }) : _durasiServer = durasiHari,
       _terlaluLamaServer = terlaluLama,
       _persenSusutServer = persenSusut,
       _bolehDiselesaikanServer = bolehDiselesaikan,
       _palingCepatSelesaiServer = tanggalPalingCepatSelesai;

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
      durasiHari: j['durasi_hari'] == null ? null : parseId(j['durasi_hari']),
      terlaluLama: j['terlalu_lama'] is bool ? j['terlalu_lama'] as bool : null,
      persenSusut: num_(j['persen_susut']),
      bolehDiselesaikan: j['boleh_diselesaikan'] is bool
          ? j['boleh_diselesaikan'] as bool
          : null,
      tanggalPalingCepatSelesai: tgl(j['tanggal_paling_cepat_selesai']),
    );
  }

  /// Sudah dijemur cukup lama (minimal [minHariJemur] hari) untuk diselesaikan.
  /// Memakai keputusan server; hitungan lokal hanya cadangan.
  bool get bolehDiselesaikan =>
      _bolehDiselesaikanServer ??
      (status == StatusPenjemuran.dijemur && (durasiHari ?? 0) >= minHariJemur);

  /// Tanggal paling cepat penjemuran boleh diselesaikan (mulai + [minHariJemur] hari).
  DateTime? get tanggalPalingCepatSelesai {
    if (_palingCepatSelesaiServer != null) return _palingCepatSelesaiServer;
    final mulai = tanggalMulai;
    if (mulai == null) return null;
    return DateTime(mulai.year, mulai.month, mulai.day + minHariJemur);
  }

  /// Durasi jemur dalam hari (berjalan sampai hari ini bila belum selesai).
  /// Memakai angka server bila ada; hitungan lokal hanya cadangan.
  int? get durasiHari {
    if (_durasiServer != null) return _durasiServer;
    if (tanggalMulai == null) return null;
    final akhir = status == StatusPenjemuran.dijemur || tanggalSelesai == null
        ? DateTime.now()
        : tanggalSelesai!;
    final a = DateTime(
      tanggalMulai!.year,
      tanggalMulai!.month,
      tanggalMulai!.day,
    );
    final b = DateTime(akhir.year, akhir.month, akhir.day);
    final hari = b.difference(a).inDays;
    return hari < 0 ? 0 : hari;
  }

  bool get terlaluLama =>
      _terlaluLamaServer ??
      (status == StatusPenjemuran.dijemur &&
          (durasiHari ?? 0) > batasDurasiTerlaluLama);

  /// Persen susut = (basah - kering) / basah x 100
  double? get persenSusut =>
      _persenSusutServer ?? hitungSusut(beratBasah, beratKering);
}

double? hitungSusut(double basah, double? kering) =>
    (basah > 0 && kering != null) ? (basah - kering) / basah * 100 : null;
