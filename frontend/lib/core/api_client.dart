import 'dart:convert';

import 'package:http/http.dart' as http;

/// Klien HTTP untuk API Laravel (envelope {success, message, data, errors}).
///
/// Alamat backend:
/// - Emulator Android: `10.0.2.2` menunjuk ke mesin host (default di bawah).
/// - Perangkat fisik: ganti ke IP komputer di LAN, mis. `192.168.1.5`.
/// - Jalankan backend dengan `php artisan serve --host=0.0.0.0 --port=8000`.
class ApiClient {
  static const _dasar = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static String get dasar => _dasar;

  /// Klien HTTP yang dipakai; bisa diganti (mis. `MockClient`) saat test.
  http.Client klien;

  ApiClient({http.Client? klien}) : klien = klien ?? http.Client();

  String? token;

  /// Dipanggil saat server menjawab 401 untuk permintaan yang membawa token
  /// (token kedaluwarsa, dicabut, atau akun dinonaktifkan). Sesi memakainya
  /// untuk kembali ke halaman login.
  void Function()? onSesiBerakhir;

  Uri _uri(String path) => Uri.parse('$_dasar$path');

  Map<String, String> _header({bool json = true}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<ApiJawaban> get(String path) => _kirim('GET', path);

  Future<ApiJawaban> post(String path, [Map<String, dynamic>? body]) =>
      _kirim('POST', path, body);

  Future<ApiJawaban> put(String path, [Map<String, dynamic>? body]) =>
      _kirim('PUT', path, body);

  Future<ApiJawaban> delete(String path) => _kirim('DELETE', path);

  /// Ambil seluruh isi daftar berpaginasi (`data.items` + `data.meta.total`)
  /// dengan memuat halaman demi halaman, supaya data ke-101 dan seterusnya
  /// tidak hilang. Berhenti bila semua sudah terambil, halaman kosong, atau
  /// [maksHalaman] tercapai (pengaman).
  Future<HasilDaftar> getSemuaHalaman(
    String path, {
    int limit = 100,
    int maksHalaman = 50,
  }) async {
    final items = <Map<String, dynamic>>[];
    var total = 0;
    final sambung = path.contains('?') ? '&' : '?';

    for (var halaman = 1; halaman <= maksHalaman; halaman++) {
      final jwb = await get('$path${sambung}limit=$limit&page=$halaman');
      if (!jwb.sukses || jwb.data is! Map) {
        return HasilDaftar(items: items, total: total, galat: jwb);
      }
      final data = jwb.data as Map<String, dynamic>;
      final baris = (data['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final meta = data['meta'];
      total = meta is Map ? (meta['total'] as num?)?.toInt() ?? 0 : 0;

      items.addAll(baris);
      if (baris.isEmpty || items.length >= total) break;
    }
    return HasilDaftar(items: items, total: total);
  }

  Future<ApiJawaban> _kirim(
    String metode,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final uri = _uri(path);
      final req = http.Request(metode, uri)
        ..headers.addAll(_header(json: body != null));
      if (body != null) req.body = jsonEncode(body);

      final streamed = await klien
          .send(req)
          .timeout(const Duration(seconds: 15));
      final jwb = await http.Response.fromStream(streamed);

      Map<String, dynamic>? muatan;
      try {
        final decoded = jsonDecode(jwb.body);
        if (decoded is Map<String, dynamic>) muatan = decoded;
      } catch (_) {
        // Respons bukan JSON (mis. halaman error server): abaikan
      }

      // Token ditolak: sesi dianggap berakhir. Login yang salah juga 401 tetapi
      // belum membawa token, jadi tidak dianggap sesi berakhir.
      if (jwb.statusCode == 401) {
        final punyaToken = token != null;
        token = null;
        if (punyaToken) onSesiBerakhir?.call();
      }

      return ApiJawaban(
        status: jwb.statusCode,
        sukses: jwb.statusCode >= 200 && jwb.statusCode < 300,
        pesan:
            muatan?['message'] as String? ??
            'Permintaan gagal (HTTP ${jwb.statusCode})',
        data: muatan?['data'],
        errors: _rataErrors(muatan?['errors']),
      );
    } on Exception {
      return ApiJawaban(
        status: 0,
        sukses: false,
        pesan: 'Tidak dapat terhubung ke server. Pastikan backend berjalan.',
      );
    }
  }

  /// `errors` backend berupa daftar {field, message}; ratakan jadi map field→pesan
  static Map<String, String> _rataErrors(dynamic errors) {
    final hasil = <String, String>{};
    if (errors is List) {
      for (final e in errors) {
        if (e is Map && e['field'] != null && e['message'] != null) {
          hasil[e['field'].toString()] = e['message'].toString();
        }
      }
    }
    return hasil;
  }
}

/// Hasil [ApiClient.getSemuaHalaman]. Bila [galat] terisi, [items] hanya
/// berisi halaman yang sempat terambil sebelum gagal.
class HasilDaftar {
  final List<Map<String, dynamic>> items;
  final int total;
  final ApiJawaban? galat;

  const HasilDaftar({required this.items, required this.total, this.galat});
}

class ApiJawaban {
  final int status;
  final bool sukses;
  final String pesan;
  final dynamic data;
  final Map<String, String> errors;

  const ApiJawaban({
    required this.status,
    required this.sukses,
    required this.pesan,
    this.data,
    this.errors = const {},
  });
}
