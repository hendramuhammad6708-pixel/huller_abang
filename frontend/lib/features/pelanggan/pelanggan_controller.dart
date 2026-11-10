import 'package:flutter/foundation.dart';

import '../../core/sesi.dart';
import 'models/pelanggan.dart';

/// Daftar pelanggan dari API backend (GET/POST/PUT/DELETE /api/pelanggan).
/// Filter pencarian/tipe berjalan lokal di atas data yang sudah dimuat
/// (cukup untuk skala data huller; server mendukung ?search=&tipe= bila perlu).
class PelangganController extends ChangeNotifier {
  final Sesi _sesi = Sesi.instance;

  List<Pelanggan> _items = [];
  bool _memuat = false;
  String? _galat;

  List<Pelanggan> get items => List.unmodifiable(_items);
  bool get memuat => _memuat;
  String? get galat => _galat;

  Future<void> muat({bool paksa = false}) async {
    if (_memuat || (_items.isNotEmpty && !paksa)) return;
    _memuat = true;
    _galat = null;
    notifyListeners();

    final jwb = await _sesi.api.get('/pelanggan?limit=100');
    if (jwb.sukses && jwb.data is Map) {
      final data = jwb.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      _items = items
          .whereType<Map<String, dynamic>>()
          .map(Pelanggan.dariApi)
          .toList();
    } else {
      _galat = jwb.pesan;
    }

    _memuat = false;
    notifyListeners();
  }

  /// Tambah; lempar [ApiJawaban] bila validasi 422 (cek `errors` per field).
  /// Mengembalikan pelanggan hasil simpan (termasuk id dari server).
  Future<Pelanggan> tambah(Pelanggan p) async {
    final jwb = await _sesi.api.post('/pelanggan', p.keApi());
    if (!jwb.sukses) throw jwb;

    var hasil = p;
    if (jwb.data is Map) {
      final data = Map<String, dynamic>.from(jwb.data as Map);
      if (data['id'] != null && data['nama'] is String) {
        hasil = Pelanggan.dariApi(data);
      }
    }

    if (hasil.id != null && !_items.any((e) => e.id == hasil.id)) {
      _items = [..._items, hasil]
        ..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
      notifyListeners();
    }

    return hasil;
  }

  /// Ubah; lempar [ApiJawaban] bila validasi 422 atau 404.
  Future<void> ubah(Pelanggan p) async {
    final jwb = await _sesi.api.put('/pelanggan/${p.id}', p.keApi());
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }

  /// Hapus; lempar [ApiJawaban] bila 404.
  Future<void> hapus(int id) async {
    final jwb = await _sesi.api.delete('/pelanggan/$id');
    if (!jwb.sukses) throw jwb;
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
