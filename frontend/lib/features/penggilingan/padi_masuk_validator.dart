/// Validator klien untuk form padi masuk; aturan mengikuti kontrak /padi-masuk.
class PadiMasukValidator {
  static String? pelanggan(int? id) => id == null ? 'Pilih pelanggan' : null;

  static String? kelas(int? id) => id == null ? 'Pilih kelas padi' : null;

  /// Menerima koma atau titik desimal; harus lebih dari 0.
  static double? parseBerat(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', '.'));

  static String? berat(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Berat wajib diisi';
    final n = parseBerat(v);
    if (n == null) return 'Berat harus berupa angka';
    if (n <= 0) return 'Berat harus lebih dari 0';
    if (n > 1000000) return 'Berat terlalu besar';
    return null;
  }

  /// Tanggal tidak boleh di masa depan. [sekarang] untuk keperluan test.
  static String? tanggal(DateTime? d, {DateTime? sekarang}) {
    if (d == null) return 'Tanggal wajib diisi';
    final now = sekarang ?? DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    if (DateTime(d.year, d.month, d.day).isAfter(hariIni)) {
      return 'Tanggal tidak boleh di masa depan';
    }
    return null;
  }

  static String? catatan(String? v) {
    if ((v ?? '').trim().length > 255) return 'Catatan maksimal 255 karakter';
    return null;
  }
}
