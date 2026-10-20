import 'package:flutter/foundation.dart';

import '../../core/sesi.dart';

/// Kelas/jenis beras dari master backend (GET/POST/PUT/DELETE /api/kelas-padi).
class KelasBeras {
  final int id;
  final String nama;
  const KelasBeras(this.id, this.nama);
}

/// Hasil bagi hasil dari satu kali penggilingan (kalkulasi lokal, Sprint 2
/// akan memakai data transaksi nyata dari backend).
class BagiHasil {
  final double upahKg;
  final double operatorKg;
  final double hullerKg;
  final double saldoPelangganKg;

  const BagiHasil({
    required this.upahKg,
    required this.operatorKg,
    required this.hullerKg,
    required this.saldoPelangganKg,
  });

  /// [persenUpah]: upah huller dari beras bersih.
  /// [persenOperator]: bagian operator dari upah; sisanya milik huller.
  factory BagiHasil.hitung(
    double berasBersihKg,
    double persenUpah,
    double persenOperator,
  ) {
    final upah = berasBersihKg * persenUpah / 100;
    final op = upah * persenOperator / 100;
    return BagiHasil(
      upahKg: upah,
      operatorKg: op,
      hullerKg: upah - op,
      saldoPelangganKg: berasBersihKg - upah,
    );
  }
}

/// Pengaturan persentase + master kelas beras dari API backend.
class PengaturanController extends ChangeNotifier {
  final Sesi _sesi = Sesi.instance;

  double _persenUpah = 5;
  double _persenOperator = 5;
  List<KelasBeras> _kelas = [];
  bool _memuat = false;
  String? _galat;

  double get persenUpah => _persenUpah;
  double get persenOperator => _persenOperator;
  List<KelasBeras> get kelas => List.unmodifiable(_kelas);
  bool get memuat => _memuat;
  String? get galat => _galat;

  Future<void> muat({bool paksa = false}) async {
    if (_memuat || (_kelas.isNotEmpty && !paksa)) return;
    _memuat = true;
    _galat = null;
    notifyListeners();

    final jwbPengaturan = await _sesi.api.get('/pengaturan');
    final jwbKelas = await _sesi.api.get('/kelas-padi');

    if (jwbPengaturan.sukses && jwbPengaturan.data is Map) {
      final data = jwbPengaturan.data as Map<String, dynamic>;
      _persenUpah = (data['persen_upah'] as num?)?.toDouble() ?? 5;
      _persenOperator =
          (data['persen_hak_operator'] as num?)?.toDouble() ?? 5;
    } else {
      _galat = jwbPengaturan.pesan;
    }

    if (jwbKelas.sukses && jwbKelas.data is Map) {
      final items =
          (jwbKelas.data as Map<String, dynamic>)['items'] as List<dynamic>? ??
              [];
      _kelas = items
          .whereType<Map<String, dynamic>>()
          .map((e) => KelasBeras(
                e['id'] as int,
                e['nama_kelas'] as String,
              ))
          .toList();
    } else {
      _galat ??= jwbKelas.pesan;
    }

    _memuat = false;
    notifyListeners();
  }

  /// Simpan persentase ke backend; lempar [ApiJawaban] bila gagal/422.
  Future<void> simpanPersentase(double upah, double operator) async {
    final jwb = await _sesi.api.put('/pengaturan', {
      'persen_upah': upah,
      'persen_hak_operator': operator,
    });
    if (!jwb.sukses) throw jwb;
    _persenUpah = upah;
    _persenOperator = operator;
    notifyListeners();
  }

  Future<void> tambahKelas(String nama) async {
    final jwb = await _sesi.api.post('/kelas-padi', {'nama_kelas': nama});
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }

  Future<void> ubahKelas(int id, String nama) async {
    final jwb = await _sesi.api.put('/kelas-padi/$id', {'nama_kelas': nama});
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }

  Future<void> hapusKelas(int id) async {
    final jwb = await _sesi.api.delete('/kelas-padi/$id');
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }
}

/// Parser & validator persen (menerima koma atau titik desimal).
double? parsePersen(String? v) =>
    double.tryParse((v ?? '').trim().replaceAll(',', '.'));

String? validatorPersen(String? v, String label) {
  if ((v ?? '').trim().isEmpty) return '$label wajib diisi';
  final n = parsePersen(v);
  if (n == null) return '$label harus berupa angka';
  if (n < 0 || n > 100) return '$label harus antara 0 dan 100';
  return null;
}

String formatPersen(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
