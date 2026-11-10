import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart';
import '../../../core/sesi.dart';
import 'penjemuran_model.dart';

/// Gunakan base URL dari ApiClient (sama dengan sisa app).
class PenjemuranService {
  PenjemuranService({Future<String?> Function()? tokenGetter});

  Future<Map<String, String>> _headers() async {
    final token = Sesi.instance.token ?? Sesi.instance.api.token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiClient.dasar.replaceAll(RegExp(r'/api/?$'), '');
    final uri = Uri.parse('$base/api$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  dynamic _handle(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body['data'] ?? body;
    throw Exception((body is Map ? body['message'] : null) ?? 'Permintaan gagal (${res.statusCode})');
  }

  Future<List<Penjemuran>> ambilSemua({
    String? status,
    int? pelangganId,
    DateTime? tanggalDari,
    DateTime? tanggalSampai,
  }) async {
    final q = <String, String>{};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (pelangganId != null) q['pelanggan_id'] = pelangganId.toString();
    if (tanggalDari != null) q['tanggal_dari'] = _fmt(tanggalDari);
    if (tanggalSampai != null) q['tanggal_sampai'] = _fmt(tanggalSampai);

    final res = await http
        .get(_uri('/penjemuran', q), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final data = _handle(res);
    if (data is List) {
      return data.map((e) => Penjemuran.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> mulai(int id, DateTime tanggalMulai) async {
    final res = await http.post(
      _uri('/penjemuran/$id/mulai'),
      headers: await _headers(),
      body: jsonEncode({'tanggal_mulai': _fmt(tanggalMulai)}),
    );
    _handle(res);
  }

  Future<void> selesai(int id, DateTime tanggalSelesai, double beratKering) async {
    final res = await http.post(
      _uri('/penjemuran/$id/selesai'),
      headers: await _headers(),
      body: jsonEncode({'tanggal_selesai': _fmt(tanggalSelesai), 'berat_kering': beratKering}),
    );
    _handle(res);
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}