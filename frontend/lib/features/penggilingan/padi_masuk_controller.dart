import 'package:flutter/material.dart';

import '../../core/sesi.dart';
import 'models/padi_masuk.dart';

/// Riwayat padi masuk dari API (GET/POST/DELETE /api/padi-masuk).
/// Filter tanggal/pelanggan/kelas dikirim ke server sebagai query string.
class PadiMasukController extends ChangeNotifier {
  final Sesi _sesi = Sesi.instance;

  List<PadiMasuk> _items = [];
  bool _memuat = false;
  bool _sudahMuat = false;
  String? _galat;
  int _permintaan = 0;

  DateTimeRange? _rentang;
  int? _pelangganId;
  int? _kelasId;

  List<PadiMasuk> get items => List.unmodifiable(_items);
  bool get memuat => _memuat;
  String? get galat => _galat;
  DateTimeRange? get rentang => _rentang;
  int? get pelangganId => _pelangganId;
  int? get kelasId => _kelasId;

  bool get adaFilter =>
      _rentang != null || _pelangganId != null || _kelasId != null;

  double get totalKg => _items.fold(0, (jumlah, e) => jumlah + e.beratKg);

  /// Path dengan query filter yang sedang aktif.
  String get path {
    final q = <String>['limit=100'];
    if (_rentang != null) {
      q.add('dari=${tanggalApi(_rentang!.start)}');
      q.add('sampai=${tanggalApi(_rentang!.end)}');
    }
    if (_pelangganId != null) q.add('pelanggan_id=$_pelangganId');
    if (_kelasId != null) q.add('kelas_padi_id=$_kelasId');
    return '/padi-masuk?${q.join('&')}';
  }

  Future<void> muat({bool paksa = false}) async {
    if (!paksa && _sudahMuat) return;
    // Hanya respons permintaan terbaru yang dipakai (filter bisa berganti cepat)
    final saya = ++_permintaan;
    _memuat = true;
    _galat = null;
    notifyListeners();

    final jwb = await _sesi.api.get(path);
    if (saya != _permintaan) return;

    if (jwb.sukses && jwb.data is Map) {
      final data = jwb.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      _items = items
          .whereType<Map<String, dynamic>>()
          .map(PadiMasuk.dariApi)
          .toList();
      _sudahMuat = true;
    } else {
      _galat = jwb.pesan;
    }

    _memuat = false;
    notifyListeners();
  }

  Future<void> setFilter({
    DateTimeRange? rentang,
    int? pelangganId,
    int? kelasId,
    bool hapusRentang = false,
    bool hapusPelanggan = false,
    bool hapusKelas = false,
  }) {
    if (hapusRentang) {
      _rentang = null;
    } else if (rentang != null) {
      _rentang = rentang;
    }
    if (hapusPelanggan) {
      _pelangganId = null;
    } else if (pelangganId != null) {
      _pelangganId = pelangganId;
    }
    if (hapusKelas) {
      _kelasId = null;
    } else if (kelasId != null) {
      _kelasId = kelasId;
    }
    return muat(paksa: true);
  }

  Future<void> resetFilter() {
    _rentang = null;
    _pelangganId = null;
    _kelasId = null;
    return muat(paksa: true);
  }

  /// Tambah; lempar [ApiJawaban] bila validasi 422 (cek `errors` per field).
  Future<void> tambah(PadiMasuk p) async {
    final jwb = await _sesi.api.post('/padi-masuk', p.keApi());
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }

  /// Hapus; lempar [ApiJawaban] bila 404.
  Future<void> hapus(int id) async {
    final jwb = await _sesi.api.delete('/padi-masuk/$id');
    if (!jwb.sukses) throw jwb;
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
