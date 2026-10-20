import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huller_abang/features/auth/login_page.dart';
import 'package:huller_abang/features/pelanggan/models/pelanggan.dart';
import 'package:huller_abang/features/pelanggan/pelanggan_validator.dart';
import 'package:huller_abang/features/pengaturan/pengaturan_controller.dart';

void main() {
  group('bagi hasil', () {
    test('sesuai contoh desain (825 kg, upah 5%, operator 30%)', () {
      final h = BagiHasil.hitung(825, 5, 30);
      expect(h.upahKg, closeTo(41.25, 0.001));
      expect(h.operatorKg, closeTo(12.375, 0.001));
      expect(h.saldoPelangganKg, closeTo(783.75, 0.001));
    });

    test('operator 5% dari upah', () {
      final h = BagiHasil.hitung(1000, 5, 5);
      expect(h.upahKg, closeTo(50, 0.001));
      expect(h.operatorKg, closeTo(2.5, 0.001));
      expect(h.hullerKg, closeTo(47.5, 0.001));
    });
  });

  group('validator pelanggan (disamakan dengan backend)', () {
    test('nama wajib dan maksimal 100 karakter', () {
      expect(PelangganValidator.nama(''), isNotNull);
      expect(PelangganValidator.nama(null), isNotNull);
      expect(PelangganValidator.nama('Pak Warsito'), isNull);
      expect(PelangganValidator.nama('x' * 101), isNotNull);
    });

    test('kontak opsional; jika diisi 8–15 digit angka', () {
      expect(PelangganValidator.kontak(''), isNull);
      expect(PelangganValidator.kontak('0812345678'), isNull);
      expect(PelangganValidator.kontak('+6281234567890'), isNull);
      expect(PelangganValidator.kontak('123'), isNotNull);
      expect(PelangganValidator.kontak('0812abc5678'), isNotNull);
    });
  });

  group('model pelanggan ↔ API', () {
    test('dariApi membaca envelope backend', () {
      final p = Pelanggan.dariApi({
        'id': 7,
        'nama': 'Pak Budi',
        'kontak': '081234567890',
        'tipe_pelanggan': 'pengepul',
      });
      expect(p.id, 7);
      expect(p.tipe, TipePelanggan.pengepul);
    });

    test('keApi memakai kunci tipe_pelanggan', () {
      const p = Pelanggan(nama: 'Pak Budi', tipe: TipePelanggan.milikHuller);
      final api = p.keApi();
      expect(api['tipe_pelanggan'], 'milik_huller');
      expect(api['kontak'], isNull); // kontak kosong → null (opsional)
    });

    test('inisial tanpa sapaan', () {
      const p = Pelanggan(nama: 'H. Solihin Wijaya', tipe: TipePelanggan.petani);
      expect(p.inisial, 'SW');
    });
  });

  group('validator persen pengaturan', () {
    test('menerima koma dan titik', () {
      expect(parsePersen('5,5'), closeTo(5.5, 0.001));
      expect(parsePersen('5.5'), closeTo(5.5, 0.001));
    });

    test('menolak di luar 0–100', () {
      expect(validatorPersen('150', 'Upah'), isNotNull);
      expect(validatorPersen('-1', 'Upah'), isNotNull);
      expect(validatorPersen('50', 'Upah'), isNull);
    });
  });

  group('halaman login', () {
    Future<void> buka(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: const LoginPage()));
    }

    testWidgets('menolak submit saat kedua field kosong', (tester) async {
      await buka(tester);
      await tester.tap(find.byKey(const Key('btn-masuk')));
      await tester.pump();
      expect(find.text('Username wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('menampilkan form login', (tester) async {
      await buka(tester);
      expect(find.byKey(const Key('field-username')), findsOneWidget);
      expect(find.byKey(const Key('field-password')), findsOneWidget);
      expect(find.text('HULLER ABANG'), findsOneWidget);
    });
  });
}
