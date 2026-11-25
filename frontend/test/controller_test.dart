import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huller_abang/core/sesi.dart';
import 'package:huller_abang/features/pelanggan/pelanggan_controller.dart';
import 'package:huller_abang/features/pelanggan/riwayat_transaksi_controller.dart';
import 'package:huller_abang/features/penggilingan/padi_masuk_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object isi, [int status = 200]) => http.Response(
  jsonEncode(isi),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _padi(
  int id, {
  String status = 'masuk',
  num berat = 100,
}) => {
  'id': id,
  'tanggal': '2026-10-27',
  'pelanggan_id': 1,
  'nama_pelanggan': 'Pak Budi',
  'kelas_padi_id': 1,
  'nama_kelas': 'Premium',
  'berat_basah_kg': berat,
  'status': status,
};

Map<String, dynamic> _daftar(List<Map<String, dynamic>> items, Map meta) => {
  'success': true,
  'message': 'ok',
  'data': {'items': items, 'meta': meta},
};

void main() {
  final api = Sesi.instance.api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api.token = null;
  });

  group('PelangganController', () {
    test('memuat semua halaman, bukan hanya 100 pertama', () async {
      api.klien = MockClient((req) async {
        final page = int.parse(req.url.queryParameters['page']!);
        final id = page == 1 ? [1, 2] : [3];
        return _json(
          _daftar(
            [
              for (final i in id)
                {
                  'id': i,
                  'nama': 'P$i',
                  'kontak': null,
                  'tipe_pelanggan': 'petani',
                },
            ],
            {'total': 3},
          ),
        );
      });
      final c = PelangganController();

      await c.muat();

      expect(c.items.map((e) => e.id), [1, 2, 3]);
      expect(c.galat, isNull);
    });

    test('galat server ditampilkan sebagai pesan', () async {
      api.klien = MockClient(
        (_) async => _json({'success': false, 'message': 'Gagal'}, 500),
      );
      final c = PelangganController();

      await c.muat();

      expect(c.items, isEmpty);
      expect(c.galat, 'Gagal');
    });
  });

  group('PadiMasukController (muat bertahap)', () {
    test(
      'muat lalu muatLagi menambah halaman berikutnya tanpa baris ganda',
      () async {
        final diminta = <int>[];
        api.klien = MockClient((req) async {
          final page = int.parse(req.url.queryParameters['page'] ?? '1');
          diminta.add(page);
          final items = page == 1 ? [_padi(3), _padi(2)] : [_padi(2), _padi(1)];
          return _json(
            _daftar(items, {
              'total': 3,
              'jumlah_aktif': 3,
              'total_berat_kg': 300,
            }),
          );
        });
        final c = PadiMasukController();

        await c.muat();
        expect(c.items.length, 2);
        expect(c.adaLagi, isTrue);

        await c.muatLagi();

        // id 2 muncul di kedua halaman (data bergeser) tetapi hanya dihitung sekali
        expect(c.items.map((e) => e.id), [3, 2, 1]);
        expect(c.adaLagi, isFalse);
        expect(diminta, [1, 2]);
      },
    );

    test('ringkasan memakai angka server untuk seluruh hasil filter', () async {
      api.klien = MockClient(
        (_) async => _json(
          _daftar(
            [_padi(1, berat: 10)],
            {'total': 50, 'jumlah_aktif': 48, 'total_berat_kg': 4800.5},
          ),
        ),
      );
      final c = PadiMasukController();

      await c.muat();

      // Hanya 1 baris dimuat, tetapi ringkasan mencakup 50 transaksi
      expect(c.items.length, 1);
      expect(c.jumlahAktif, 48);
      expect(c.totalKg, 4800.5);
    });

    test(
      'tanpa ringkasan server, dihitung dari data yang dimuat tanpa void',
      () async {
        api.klien = MockClient(
          (_) async => _json(
            _daftar(
              [
                _padi(1, berat: 100),
                _padi(2, berat: 50),
                _padi(3, status: 'void', berat: 999),
              ],
              {'total': 3},
            ),
          ),
        );
        final c = PadiMasukController();

        await c.muat();

        expect(c.jumlahAktif, 2);
        expect(c.totalKg, 150);
      },
    );

    test(
      'muatLagi tidak melakukan apa-apa bila semua data sudah dimuat',
      () async {
        var panggilan = 0;
        api.klien = MockClient((_) async {
          panggilan++;
          return _json(_daftar([_padi(1)], {'total': 1}));
        });
        final c = PadiMasukController();

        await c.muat();
        await c.muatLagi();

        expect(panggilan, 1);
      },
    );
  });

  group('RiwayatTransaksiController', () {
    test('membaca status terakhir, total, dan daftar transaksi', () async {
      api.klien = MockClient((req) async {
        expect(req.url.path, endsWith('/pelanggan/9/riwayat-transaksi'));
        return _json({
          'success': true,
          'message': 'ok',
          'data': {
            'pelanggan': {
              'status_terakhir': 'dijemur',
              'status_terakhir_label': 'Dijemur',
              'tanggal_terakhir': '2026-10-26',
            },
            'items': [_padi(1), _padi(2)],
            'meta': {'total': 12},
          },
        });
      });
      final c = RiwayatTransaksiController(9);

      await c.muat();

      expect(c.total, 12);
      expect(c.items.length, 2);
      expect(c.statusTerakhir, 'dijemur');
      expect(c.tanggalTerakhir, DateTime(2026, 10, 26));
    });
  });

  group('Sesi', () {
    Map<String, dynamic> userJson() => {
      'id': 1,
      'nama': 'Operator',
      'username': 'op',
      'role': 'operator',
      'aktif': true,
    };

    test(
      '401 saat sudah login mengeluarkan pengguna dan menyimpan pesan',
      () async {
        api.klien = MockClient((req) async {
          if (req.url.path.endsWith('/login')) {
            return _json({
              'success': true,
              'message': 'ok',
              'data': {'token': 'tkn', 'user': userJson()},
            });
          }
          return _json({'success': false, 'message': 'Sesi berakhir'}, 401);
        });
        final sesi = Sesi.instance;

        await sesi.login('op', 'rahasia');
        expect(sesi.sudahLogin, isTrue);

        await api.get('/padi-masuk');
        // _sesiBerakhir berjalan async setelah callback
        await Future<void>.delayed(Duration.zero);

        expect(sesi.sudahLogin, isFalse);
        expect(sesi.token, isNull);
        expect(sesi.ambilPesanSesi(), contains('Sesi Anda telah berakhir'));
        // Pesan hanya ditampilkan sekali
        expect(sesi.ambilPesanSesi(), isNull);
      },
    );
  });
}
