import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huller_abang/core/api_client.dart';
import 'package:huller_abang/features/penjemuran/penjemuran_model.dart';
import 'package:huller_abang/features/penjemuran/penjemuran_service.dart';

http.Response _json(Object isi, [int status = 200]) => http.Response(
  jsonEncode(isi),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _halaman(List<int> id, int total) => {
  'success': true,
  'message': 'ok',
  'data': {
    'items': [
      for (final i in id) {'id': i},
    ],
    'meta': {'total': total},
  },
};

void main() {
  group('getSemuaHalaman', () {
    test('memuat halaman demi halaman sampai semua data terambil', () async {
      final diminta = <String>[];
      final api = ApiClient(
        klien: MockClient((req) async {
          diminta.add(req.url.query);
          final page = int.parse(req.url.queryParameters['page']!);
          return _json(switch (page) {
            1 => _halaman([1, 2], 5),
            2 => _halaman([3, 4], 5),
            _ => _halaman([5], 5),
          });
        }),
      );

      final hasil = await api.getSemuaHalaman('/pelanggan', limit: 2);

      expect(hasil.galat, isNull);
      expect(hasil.items.map((e) => e['id']), [1, 2, 3, 4, 5]);
      expect(hasil.total, 5);
      expect(diminta.length, 3);
      expect(diminta.first, 'limit=2&page=1');
    });

    test('path yang sudah punya query disambung dengan &', () async {
      late Uri uri;
      final api = ApiClient(
        klien: MockClient((req) async {
          uri = req.url;
          return _json(_halaman([1], 1));
        }),
      );

      await api.getSemuaHalaman('/pelanggan?tipe=petani');

      expect(uri.queryParameters, {
        'tipe': 'petani',
        'limit': '100',
        'page': '1',
      });
    });

    test('berhenti dan melaporkan galat bila satu halaman gagal', () async {
      final api = ApiClient(
        klien: MockClient((req) async {
          final page = req.url.queryParameters['page'];
          return page == '1'
              ? _json(_halaman([1, 2], 10))
              : _json({'success': false, 'message': 'Server error'}, 500);
        }),
      );

      final hasil = await api.getSemuaHalaman('/pelanggan', limit: 2);

      expect(hasil.galat?.pesan, 'Server error');
      expect(hasil.items.length, 2);
    });

    test(
      'halaman kosong menghentikan pemuatan walau total lebih besar',
      () async {
        var panggilan = 0;
        final api = ApiClient(
          klien: MockClient((req) async {
            panggilan++;
            return _json(_halaman([], 99));
          }),
        );

        final hasil = await api.getSemuaHalaman('/pelanggan');

        expect(hasil.items, isEmpty);
        expect(panggilan, 1);
      },
    );
  });

  group('sesi berakhir (401)', () {
    test('401 pada permintaan bertoken memanggil onSesiBerakhir', () async {
      var dipanggil = 0;
      final api =
          ApiClient(
              klien: MockClient(
                (_) async =>
                    _json({'success': false, 'message': 'Sesi berakhir'}, 401),
              ),
            )
            ..token = 'abc'
            ..onSesiBerakhir = () => dipanggil++;

      final jwb = await api.get('/me');

      expect(jwb.status, 401);
      expect(api.token, isNull);
      expect(dipanggil, 1);
    });

    test('login salah (401 tanpa token) bukan sesi berakhir', () async {
      var dipanggil = 0;
      final api = ApiClient(
        klien: MockClient(
          (_) async => _json({'success': false, 'message': 'Salah'}, 401),
        ),
      )..onSesiBerakhir = () => dipanggil++;

      await api.post('/login', {'username': 'x', 'password': 'y'});

      expect(dipanggil, 0);
    });

    test('server tidak terjangkau menghasilkan status 0', () async {
      final api = ApiClient(
        klien: MockClient((_) async => throw http.ClientException('putus')),
      );

      final jwb = await api.get('/me');

      expect(jwb.status, 0);
      expect(jwb.sukses, isFalse);
    });
  });

  group('PenjemuranService', () {
    test('ambilSemua membaca daftar dan menyertakan filter', () async {
      late Uri uri;
      final service = PenjemuranService(
        api: ApiClient(
          klien: MockClient((req) async {
            uri = req.url;
            return _json({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 4,
                  'pelanggan': 'Pak Budi',
                  'kelas': 'Premium',
                  'tanggal_masuk': '2026-10-26',
                  'berat_basah': 200,
                  'status': 'dijemur',
                  'durasi_hari': 5,
                  'terlalu_lama': true,
                },
              ],
            });
          }),
        ),
      );

      final hasil = await service.ambilSemua(
        status: 'dijemur',
        tanggalDari: DateTime(2026, 10, 1),
      );

      expect(uri.path, endsWith('/penjemuran'));
      expect(uri.queryParameters, {
        'status': 'dijemur',
        'tanggal_dari': '2026-10-01',
      });
      expect(hasil.single.pelanggan, 'Pak Budi');
      expect(hasil.single.durasiHari, 5);
      expect(hasil.single.terlaluLama, isTrue);
    });

    test('galat validasi memakai pesan per field', () async {
      final service = PenjemuranService(
        api: ApiClient(
          klien: MockClient(
            (_) async => _json({
              'success': false,
              'message': 'Data tidak valid',
              'errors': [
                {
                  'field': 'berat_kering',
                  'message': 'Berat kering tidak boleh melebihi berat basah',
                },
              ],
            }, 422),
          ),
        ),
      );

      expect(
        () => service.selesai(1, DateTime(2026, 10, 27), 999),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'pesan',
            contains('tidak boleh melebihi berat basah'),
          ),
        ),
      );
    });

    test('mulai mengirim tanggal berformat YYYY-MM-DD', () async {
      late http.Request diterima;
      final service = PenjemuranService(
        api: ApiClient(
          klien: MockClient((req) async {
            diterima = req;
            return _json({'success': true, 'message': 'ok', 'data': {}});
          }),
        ),
      );

      await service.mulai(7, DateTime(2026, 3, 9));

      expect(diterima.method, 'POST');
      expect(diterima.url.path, endsWith('/penjemuran/7/mulai'));
      expect(jsonDecode(diterima.body), {'tanggal_mulai': '2026-03-09'});
    });
  });

  group('Penjemuran (angka dari server)', () {
    Map<String, dynamic> dasar(Map<String, dynamic> tambah) => {
      'id': 1,
      'pelanggan': 'A',
      'kelas': 'B',
      'tanggal_masuk': '2026-10-20',
      'berat_basah': 200,
      'status': 'dijemur',
      'tanggal_mulai': '2026-10-21',
      ...tambah,
    };

    test('memakai durasi, terlalu_lama, dan persen_susut dari server', () {
      final p = Penjemuran.fromJson(
        dasar({'durasi_hari': 2, 'terlalu_lama': false, 'persen_susut': 12.5}),
      );

      expect(p.durasiHari, 2);
      expect(p.terlaluLama, isFalse);
      expect(p.persenSusut, 12.5);
    });

    test('tanpa angka server, dihitung lokal sebagai cadangan', () {
      final p = Penjemuran.fromJson(
        dasar({
          'status': 'siap_giling',
          'tanggal_mulai': '2026-10-21',
          'tanggal_selesai': '2026-10-24',
          'berat_kering': 170,
        }),
      );

      expect(p.durasiHari, 3);
      expect(p.terlaluLama, isFalse);
      expect(p.persenSusut, 15);
    });

    test('hitungSusut: nol bila berat basah 0 atau kering belum ada', () {
      expect(hitungSusut(0, 10), isNull);
      expect(hitungSusut(100, null), isNull);
      expect(hitungSusut(200, 170), 15);
    });
  });
}
