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
  Future<void> tambah(Pelanggan p) async {
    final jwb = await _sesi.api.post('/pelanggan', p.keApi());
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
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
