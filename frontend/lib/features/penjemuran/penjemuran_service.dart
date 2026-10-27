import 'dart:convert';
import 'package:http/http.dart' as http;
import 'penjemuran_model.dart';

/// Emulator Android: 10.0.2.2 = localhost laptop. HP asli: pakai IP laptop (mis. http://192.168.1.5:8000).
/// Bisa diganti saat build: flutter run --dart-define=API_URL=http://192.168.1.5:8000
const String defaultBaseUrl =
String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

/// Kontrak endpoint (samakan dengan docs/api/penjemuran.md milik Azlan/Alya):
///   GET  /api/penjemuran                -> data: [ {id, pelanggan, kelas, tanggal_masuk, berat_basah,
///                                                   tanggal_mulai, tanggal_selesai, berat_kering, status} ]
///   POST /api/penjemuran/{id}/mulai     body {tanggal_mulai}
///   POST /api/penjemuran/{id}/selesai   body {tanggal_selesai, berat_kering}
class PenjemuranService {
  final String baseUrl;

  /// Isi dengan fungsi pengambil token login yang sudah dipakai di fitur auth.
  final Future<String?> Function()? tokenGetter;

  PenjemuranService({this.baseUrl = defaultBaseUrl, this.tokenGetter});

  Future<Map<String, String>> _headers() async {
    final token = await tokenGetter?.call();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handle(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body['data'] ?? body;
    throw Exception((body is Map ? body['message'] : null) ?? 'Permintaan gagal (${res.statusCode})');
  }

  Future<List<Penjemuran>> ambilSemua() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/penjemuran'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final data = _handle(res) as List;
    return data.map((e) => Penjemuran.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> mulai(int id, DateTime tanggalMulai) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/penjemuran/$id/mulai'),
      headers: await _headers(),
      body: jsonEncode({'tanggal_mulai': _fmt(tanggalMulai)}),
    );
    _handle(res);
  }

  Future<void> selesai(int id, DateTime tanggalSelesai, double beratKering) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/penjemuran/$id/selesai'),
      headers: await _headers(),
      body: jsonEncode({'tanggal_selesai': _fmt(tanggalSelesai), 'berat_kering': beratKering}),
    );
    _handle(res);
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}