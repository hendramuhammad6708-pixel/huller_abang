enum TipePelanggan { petani, pengepul, milikHuller }

extension TipePelangganX on TipePelanggan {
  String get label => switch (this) {
        TipePelanggan.petani => 'Petani',
        TipePelanggan.pengepul => 'Pengepul',
        TipePelanggan.milikHuller => 'Milik Huller',
      };

  /// Nilai sesuai backend (`tipe_pelanggan`).
  String get nilaiApi => switch (this) {
        TipePelanggan.petani => 'petani',
        TipePelanggan.pengepul => 'pengepul',
        TipePelanggan.milikHuller => 'milik_huller',
      };

  static TipePelanggan dariApi(String v) => switch (v) {
        'pengepul' => TipePelanggan.pengepul,
        'milik_huller' => TipePelanggan.milikHuller,
        _ => TipePelanggan.petani,
      };
}

class Pelanggan {
  final int? id;
  final String nama;

  /// No. HP / kontak; boleh kosong (opsional di backend).
  final String kontak;
  final TipePelanggan tipe;

  const Pelanggan({
    this.id,
    required this.nama,
    this.kontak = '',
    required this.tipe,
  });

  factory Pelanggan.dariApi(Map<String, dynamic> j) => Pelanggan(
        id: j['id'] as int?,
        nama: j['nama'] as String,
        kontak: (j['kontak'] as String?) ?? '',
        tipe: TipePelangganX.dariApi(j['tipe_pelanggan'] as String? ?? 'petani'),
      );

  Map<String, dynamic> keApi() => {
        'nama': nama,
        'kontak': kontak.isEmpty ? null : kontak,
        'tipe_pelanggan': tipe.nilaiApi,
      };

  Pelanggan salinDengan({String? nama, String? kontak, TipePelanggan? tipe}) =>
      Pelanggan(
        id: id,
        nama: nama ?? this.nama,
        kontak: kontak ?? this.kontak,
        tipe: tipe ?? this.tipe,
      );

  /// Inisial dari dua kata pertama nama, tanpa sapaan (H., Pak, Bu).
  String get inisial {
    final parts = nama
        .replaceAll(RegExp(r'^(H\.|Pak|Bu)\s+'), '')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final second = parts.length > 1 ? parts[1][0] : '';
    return (parts.first[0] + second).toUpperCase();
  }
}
