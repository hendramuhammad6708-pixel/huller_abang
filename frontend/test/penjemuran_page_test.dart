import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:huller_abang/core/api_client.dart';
import 'package:huller_abang/core/app_theme.dart';
import 'package:huller_abang/features/penjemuran/penjemuran_model.dart';
import 'package:huller_abang/features/penjemuran/penjemuran_page.dart';
import 'package:huller_abang/features/penjemuran/penjemuran_service.dart';

Map<String, dynamic> _baris(
  int id, {
  required String status,
  int? durasi,
  bool? boleh,
  String? paling,
}) => {
  'id': id,
  'pelanggan': 'Pak Budi',
  'kelas': 'Premium',
  'tanggal_masuk': '2026-10-20',
  'berat_basah': 200,
  'tanggal_mulai': '2026-10-26',
  'status': status,
  'durasi_hari': durasi,
  'boleh_diselesaikan': ?boleh,
  'tanggal_paling_cepat_selesai': paling,
};

/// [diminta] (opsional) menampung semua permintaan HTTP yang dikirim halaman.
Future<void> _render(
  WidgetTester tester,
  List<Map<String, dynamic>> data, {
  List<http.Request>? diminta,
  double lebar = 400,
}) async {
  tester.view.physicalSize = Size(lebar, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = PenjemuranService(
    api: ApiClient(
      klien: MockClient((req) async {
        diminta?.add(req);
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': data}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: PenjemuranPage(service: service),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Penjemuran: minimal 2 hari sebelum diselesaikan', () {
    testWidgets(
      'dijemur kurang dari 2 hari: tombol nonaktif dan ada alasannya',
      (tester) async {
        await _render(tester, [
          _baris(
            1,
            status: 'dijemur',
            durasi: 1,
            boleh: false,
            paling: '2026-10-28',
          ),
        ]);

        final tombol = tester.widget<FilledButton>(
          find.byKey(const Key('btn-selesaikan-1')),
        );
        expect(tombol.onPressed, isNull);
        expect(
          find.byKey(const Key('info-belum-bisa-selesai-1')),
          findsOneWidget,
        );
        expect(find.textContaining('minimal 2 hari'), findsOneWidget);
        // Format tanggal sama dengan halaman lain (bukan dd/mm/yyyy)
        expect(find.textContaining('28 Okt 2026'), findsOneWidget);
      },
    );

    testWidgets('dijemur 2 hari atau lebih: tombol aktif tanpa peringatan', (
      tester,
    ) async {
      await _render(tester, [
        _baris(
          2,
          status: 'dijemur',
          durasi: 2,
          boleh: true,
          paling: '2026-10-28',
        ),
      ]);

      final tombol = tester.widget<FilledButton>(
        find.byKey(const Key('btn-selesaikan-2')),
      );
      expect(tombol.onPressed, isNotNull);
      expect(find.byKey(const Key('info-belum-bisa-selesai-2')), findsNothing);
    });
  });

  group('Penjemuran: halaman dan alur', () {
    testWidgets(
      'filter ringkas: ikon tanggal tersemat di layar sempit, tombol pelanggan yang mati hilang',
      (tester) async {
        await _render(tester, [_baris(1, status: 'masuk')]);

        // Layar 400 px: ikon tanggal tetap terlihat tanpa menggeser deretan chip
        final ikon = find.byKey(const Key('filter-tanggal-penjemuran'));
        expect(ikon, findsOneWidget);
        expect(tester.getRect(ikon).right, lessThanOrEqualTo(400));
        expect(find.text('Pelanggan'), findsNothing);
        // Chip rentang aktif baru muncul setelah memilih tanggal
        expect(find.byKey(const Key('filter-tanggal-aktif')), findsNothing);
      },
    );

    testWidgets('chip status menampilkan jumlah per status', (tester) async {
      // Layar lebar: di HP deretan chip bisa digeser, dan chip yang di luar
      // layar belum dibangun sehingga tidak bisa dicari
      await _render(tester, [
        _baris(1, status: 'masuk'),
        _baris(2, status: 'dijemur', durasi: 3, boleh: true),
        _baris(3, status: 'dijemur', durasi: 1, boleh: false),
        _baris(4, status: 'siap_giling'),
      ], lebar: 900);

      expect(find.text('Masuk (1)'), findsOneWidget);
      expect(find.text('Dijemur (2)'), findsOneWidget);
      expect(find.text('Siap Giling (1)'), findsOneWidget);
    });

    testWidgets('tanggal, berat, dan susut memakai format Indonesia', (
      tester,
    ) async {
      await _render(tester, [
        {
          ..._baris(1, status: 'siap_giling'),
          'tanggal_selesai': '2026-10-29',
          'berat_basah': 1250.5,
          'berat_kering': 1000,
          'persen_susut': 20.0,
        },
      ]);

      // Sama dengan halaman lain: titik ribuan, koma desimal, tanggal "26 Okt 2026"
      expect(find.text('1.250,50 kg'), findsOneWidget);
      expect(find.text('1.000 kg'), findsOneWidget);
      expect(find.text('20,0%'), findsOneWidget);
      expect(find.text('26 Okt 2026 - 29 Okt 2026'), findsOneWidget);
    });

    testWidgets(
      'siap giling: tombol "Selesai digiling" memanggil server setelah konfirmasi',
      (tester) async {
        final diminta = <http.Request>[];
        await _render(tester, [
          _baris(3, status: 'siap_giling'),
        ], diminta: diminta);

        await tester.tap(find.byKey(const Key('btn-selesai-giling-3')));
        await tester.pumpAndSettle();
        // Konfirmasi dulu; belum ada permintaan POST
        expect(find.byKey(const Key('dialog-selesai-giling')), findsOneWidget);
        expect(diminta.where((r) => r.method == 'POST'), isEmpty);

        await tester.tap(find.byKey(const Key('btn-ya-selesai-giling')));
        await tester.pumpAndSettle();

        final post = diminta.singleWhere((r) => r.method == 'POST');
        expect(post.url.path, endsWith('/padi-masuk/3/selesai-giling'));
      },
    );

    testWidgets('batal di dialog tidak memanggil server', (tester) async {
      final diminta = <http.Request>[];
      await _render(tester, [
        _baris(3, status: 'siap_giling'),
      ], diminta: diminta);

      await tester.tap(find.byKey(const Key('btn-selesai-giling-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belum'));
      await tester.pumpAndSettle();

      expect(diminta.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('tombol selesai digiling hanya untuk status siap giling', (
      tester,
    ) async {
      await _render(tester, [
        _baris(1, status: 'masuk'),
        _baris(2, status: 'dijemur', durasi: 3, boleh: true),
      ]);

      expect(find.byKey(const Key('btn-selesai-giling-1')), findsNothing);
      expect(find.byKey(const Key('btn-selesai-giling-2')), findsNothing);
    });
  });

  group('Penjemuran.bolehDiselesaikan', () {
    Penjemuran buat(Map<String, dynamic> j) => Penjemuran.fromJson({
      'id': 1,
      'pelanggan': 'A',
      'kelas': 'B',
      'tanggal_masuk': '2026-10-20',
      'berat_basah': 100,
      ...j,
    });

    test('memakai keputusan server', () {
      expect(
        buat({
          'status': 'dijemur',
          'tanggal_mulai': '2026-10-26',
          'durasi_hari': 5,
          'boleh_diselesaikan': false,
        }).bolehDiselesaikan,
        isFalse,
      );
    });

    test('cadangan lokal: hanya saat dijemur dan durasi >= $minHariJemur', () {
      Penjemuran p(String status, int durasi) => buat({
        'status': status,
        'tanggal_mulai': '2026-10-26',
        'durasi_hari': durasi,
      });

      expect(p('dijemur', 1).bolehDiselesaikan, isFalse);
      expect(p('dijemur', 2).bolehDiselesaikan, isTrue);
      expect(p('masuk', 5).bolehDiselesaikan, isFalse);
      expect(p('siap_giling', 5).bolehDiselesaikan, isFalse);
    });

    test(
      'tanggal paling cepat = mulai + $minHariJemur hari bila server belum mengirim',
      () {
        final p = buat({'status': 'dijemur', 'tanggal_mulai': '2026-10-26'});

        expect(p.tanggalPalingCepatSelesai, DateTime(2026, 10, 28));
      },
    );
  });
}
