import 'package:flutter/material.dart';

import '../../core/sesi.dart';
import 'models/padi_masuk.dart';

/// Riwayat padi masuk dari API (GET/POST/DELETE /api/padi-masuk).
/// Filter tanggal/pelanggan/kelas dikirim ke server sebagai query string.
class PadiMasukController extends ChangeNotifier {
  final Sesi _sesi = Sesi.instance;

  List<PadiMasuk> _items = [];
  bool _memuat = false;
  bool _memuatLagi = false;
  bool _sudahMuat = false;
  String? _galat;
  int _permintaan = 0;

  // Halaman terakhir yang sudah dimuat dan ringkasan dari server untuk SELURUH
  // hasil filter (bukan hanya halaman yang sudah terambil).
  int _halaman = 1;
  int _total = 0;
  int? _jumlahAktifServer;
  double? _totalKgServer;

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

  bool get memuatLagi => _memuatLagi;

  /// Masih ada data di halaman berikutnya.
  bool get adaLagi => _items.length < _total;

  /// Jumlah transaksi aktif (tanpa void) pada seluruh hasil filter.
  int get jumlahAktif =>
      _jumlahAktifServer ?? _items.where((e) => e.status != 'void').length;

  /// Total berat (tanpa void) pada seluruh hasil filter; cadangannya
  /// menjumlah data yang sudah dimuat bila server lama belum mengirim ringkasan.
  double get totalKg =>
      _totalKgServer ??
      _items
          .where((e) => e.status != 'void')
          .fold(0, (jumlah, e) => jumlah + e.beratKg);

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
    _memuatLagi = false;
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
      _bacaMeta(data['meta']);
      _halaman = 1;
      _sudahMuat = true;
    } else {
      _galat = jwb.pesan;
    }

    _memuat = false;
    notifyListeners();
  }

  /// Muat halaman berikutnya dan tambahkan ke daftar (tombol "Muat lebih banyak").
  Future<void> muatLagi() async {
    if (_memuat || _memuatLagi || !adaLagi) return;
    final saya = _permintaan;
    _memuatLagi = true;
    notifyListeners();

    final jwb = await _sesi.api.get('$path&page=${_halaman + 1}');
    // Filter berganti selagi memuat: hasil halaman lama dibuang
    if (saya != _permintaan) {
      _memuatLagi = false;
      return;
    }

    if (jwb.sukses && jwb.data is Map) {
      final data = jwb.data as Map<String, dynamic>;
      final baru = (data['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PadiMasuk.dariApi);
      // Cegah baris ganda bila ada transaksi baru yang menggeser halaman
      final sudah = _items.map((e) => e.id).toSet();
      _items = [..._items, ...baru.where((e) => !sudah.contains(e.id))];
      _bacaMeta(data['meta']);
      _halaman++;
    } else {
      _galat = jwb.pesan;
    }

    _memuatLagi = false;
    notifyListeners();
  }

  void _bacaMeta(dynamic meta) {
    if (meta is! Map) return;
    _total = (meta['total'] as num?)?.toInt() ?? _items.length;
    _jumlahAktifServer = (meta['jumlah_aktif'] as num?)?.toInt();
    _totalKgServer = (meta['total_berat_kg'] as num?)?.toDouble();
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

  /// Batalkan transaksi (void); lempar [ApiJawaban] bila validasi/guard gagal.
  Future<void> batalkan(int id, String alasan) async {
    final jwb = await _sesi.api.post('/padi-masuk/$id/void', {
      'alasan': alasan,
    });
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }
}
