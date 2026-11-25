import '../../core/api_client.dart';
import '../../core/sesi.dart';
import 'penjemuran_model.dart';

/// Penjemuran lewat [ApiClient] yang sama dengan fitur lain, sehingga token,
/// batas waktu, penanganan sesi berakhir (401), dan format galat seragam.
/// Galat dilempar sebagai [Exception] berisi pesan dari server.
class PenjemuranService {
  /// [api] bisa diganti untuk test; bawaannya klien milik [Sesi].
  PenjemuranService({ApiClient? api}) : _api = api ?? Sesi.instance.api;

  final ApiClient _api;

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

    final query = q.isEmpty ? '' : '?${Uri(queryParameters: q).query}';
    final data = _hasil(await _api.get('/penjemuran$query'));
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Penjemuran.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> mulai(int id, DateTime tanggalMulai) async {
    _hasil(
      await _api.post('/penjemuran/$id/mulai', {
        'tanggal_mulai': _fmt(tanggalMulai),
      }),
    );
  }

  Future<void> selesai(
    int id,
    DateTime tanggalSelesai,
    double beratKering,
  ) async {
    _hasil(
      await _api.post('/penjemuran/$id/selesai', {
        'tanggal_selesai': _fmt(tanggalSelesai),
        'berat_kering': beratKering,
      }),
    );
  }

  /// Tandai padi (berstatus Siap Giling) sudah selesai digiling. Setelah ini
  /// padi hilang dari daftar penjemuran dan transaksinya tidak bisa dibatalkan.
  Future<void> selesaiGiling(int id, {DateTime? tanggal}) async {
    _hasil(
      await _api.post(
        '/padi-masuk/$id/selesai-giling',
        tanggal == null ? null : {'tanggal_selesai_giling': _fmt(tanggal)},
      ),
    );
  }

  /// Kembalikan `data` bila sukses; bila gagal lempar pesan terperinci
  /// (galat validasi per field lebih informatif daripada "Data tidak valid").
  dynamic _hasil(ApiJawaban jwb) {
    if (jwb.sukses) return jwb.data;
    throw Exception(jwb.errors.values.firstOrNull ?? jwb.pesan);
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
