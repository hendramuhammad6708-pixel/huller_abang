/// Validator klien; aturan disamakan dengan backend (PelangganRequest).
class PelangganValidator {
  static String? nama(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Nama wajib diisi';
    if (s.length > 100) return 'Nama maksimal 100 karakter';
    return null;
  }

  /// Kontak opsional; jika diisi: angka, boleh diawali +, 8–15 digit.
  static String? kontak(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(s)) {
      return 'Kontak hanya angka, 8–15 digit (boleh diawali +)';
    }
    return null;
  }
}
