import 'package:flutter/foundation.dart';

import '../../core/sesi.dart';
import '../penggilingan/models/padi_masuk.dart';

/// Riwayat transaksi padi masuk satu pelanggan
/// (GET /api/pelanggan/{id}/riwayat-transaksi).
class RiwayatTransaksiController extends ChangeNotifier {
  final int pelangganId;
  final Sesi _sesi = Sesi.instance;

  RiwayatTransaksiController(this.pelangganId);

  List<PadiMasuk> _items = [];
  int _total = 0;
  String? _statusTerakhir;
  String? _statusTerakhirLabel;
  DateTime? _tanggalTerakhir;
  bool _memuat = false;
  bool _sudahMuat = false;
  String? _galat;

  List<PadiMasuk> get items => List.unmodifiable(_items);

  /// Jumlah seluruh transaksi (termasuk yang void), dari meta server.
  int get total => _total;
  String? get statusTerakhir => _statusTerakhir;
  String? get statusTerakhirLabel => _statusTerakhirLabel;
  DateTime? get tanggalTerakhir => _tanggalTerakhir;
  bool get memuat => _memuat;
  String? get galat => _galat;

  Future<void> muat({bool paksa = false}) async {
    if (_memuat || (_sudahMuat && !paksa)) return;
    _memuat = true;
    _galat = null;
    notifyListeners();

    final jwb = await _sesi.api.get(
      '/pelanggan/$pelangganId/riwayat-transaksi?limit=50',
    );

    if (jwb.sukses && jwb.data is Map) {
      final data = jwb.data as Map<String, dynamic>;
      final pelanggan = data['pelanggan'];
      final meta = data['meta'];
      final items = data['items'] as List<dynamic>? ?? [];

      _items = items
          .whereType<Map<String, dynamic>>()
          .map(PadiMasuk.dariApi)
          .toList();
      _total = meta is Map
          ? (meta['total'] as num?)?.toInt() ?? _items.length
          : _items.length;
      if (pelanggan is Map) {
        _statusTerakhir = pelanggan['status_terakhir'] as String?;
        _statusTerakhirLabel = pelanggan['status_terakhir_label'] as String?;
        final tgl = pelanggan['tanggal_terakhir'];
        _tanggalTerakhir = tgl == null
            ? null
            : DateTime.tryParse(tgl.toString());
      }
      _sudahMuat = true;
    } else {
      _galat = jwb.pesan;
    }

    _memuat = false;
    notifyListeners();
  }
}
