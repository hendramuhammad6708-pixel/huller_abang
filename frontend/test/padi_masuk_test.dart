import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huller_abang/features/penggilingan/models/padi_masuk.dart';
import 'package:huller_abang/features/penggilingan/padi_masuk_controller.dart';
import 'package:huller_abang/features/penggilingan/padi_masuk_validator.dart';

void main() {
  group('PadiMasukValidator', () {
    test('berat: wajib, angka, dan lebih dari 0', () {
      expect(PadiMasukValidator.berat(''), 'Berat wajib diisi');
      expect(PadiMasukValidator.berat('abc'), 'Berat harus berupa angka');
      expect(PadiMasukValidator.berat('0'), 'Berat harus lebih dari 0');
      expect(PadiMasukValidator.berat('-5'), 'Berat harus lebih dari 0');
      expect(PadiMasukValidator.berat('250,5'), isNull);
      expect(PadiMasukValidator.berat('250.5'), isNull);
    });

    test('parseBerat menerima koma atau titik', () {
      expect(PadiMasukValidator.parseBerat('250,5'), 250.5);
      expect(PadiMasukValidator.parseBerat(' 100 '), 100);
      expect(PadiMasukValidator.parseBerat('x'), isNull);
    });

    test('pelanggan dan kelas wajib dipilih', () {
      expect(PadiMasukValidator.pelanggan(null), isNotNull);
      expect(PadiMasukValidator.pelanggan(1), isNull);
      expect(PadiMasukValidator.kelas(null), isNotNull);
      expect(PadiMasukValidator.kelas(2), isNull);
    });

    test('tanggal tidak boleh di masa depan', () {
      final sekarang = DateTime(2026, 10, 27, 15);
      expect(PadiMasukValidator.tanggal(null), isNotNull);
      expect(PadiMasukValidator.tanggal(DateTime(2026, 10, 27), sekarang: sekarang),
          isNull);
      expect(PadiMasukValidator.tanggal(DateTime(2026, 10, 28), sekarang: sekarang),
          'Tanggal tidak boleh di masa depan');
    });

    test('catatan maksimal 255 karakter', () {
      expect(PadiMasukValidator.catatan(null), isNull);
      expect(PadiMasukValidator.catatan('a' * 255), isNull);
      expect(PadiMasukValidator.catatan('a' * 256), isNotNull);
    });
  });

  group('PadiMasuk', () {
    test('dariApi membaca nama relasi datar', () {
      final p = PadiMasuk.dariApi({
        'id': 7,
        'tanggal': '2026-10-27',
        'pelanggan_id': 3,
        'nama_pelanggan': 'Pak Warsito',
        'kelas_padi_id': 2,
        'nama_kelas': 'Premium',
        'berat_basah_kg': 250.5,
        'catatan': null,
      });
      expect(p.id, 7);
      expect(p.pelangganNama, 'Pak Warsito');
      expect(p.kelasNama, 'Premium');
      expect(p.beratKg, 250.5);
      expect(p.catatan, '');
      expect(p.tanggal, DateTime(2026, 10, 27));
    });

    test('dariApi membaca nama relasi bersarang dan berat integer', () {
      final p = PadiMasuk.dariApi({
        'id': 1,
        'tanggal': '2026-01-05',
        'pelanggan_id': 3,
        'pelanggan': {'nama': 'Bu Sri'},
        'kelas_padi_id': 2,
        'kelas_padi': {'nama_kelas': 'Medium'},
        'berat_basah_kg': 100,
      });
      expect(p.pelangganNama, 'Bu Sri');
      expect(p.kelasNama, 'Medium');
      expect(p.beratKg, 100.0);
    });

    test('keApi memakai snake_case dan catatan kosong jadi null', () {
      final j = PadiMasuk(
        tanggal: DateTime(2026, 3, 9),
        pelangganId: 3,
        kelasId: 2,
        beratKg: 120.5,
      ).keApi();
      expect(j, {
        'tanggal': '2026-03-09',
        'pelanggan_id': 3,
        'kelas_padi_id': 2,
        'berat_basah_kg': 120.5,
        'catatan': null,
      });
    });

    test('formatTanggal gaya Indonesia', () {
      expect(formatTanggal(DateTime(2026, 10, 27)), '27 Okt 2026');
      expect(formatTanggal(DateTime(2026, 5, 1)), '1 Mei 2026');
    });
  });

  group('PadiMasukController.path', () {
    test('tanpa filter hanya limit', () {
      expect(PadiMasukController().path, '/padi-masuk?limit=100');
    });

    test('semua filter masuk ke query string', () {
      final c = PadiMasukController();
      c.setFilter(
        rentang: DateTimeRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 27),
        ),
        pelangganId: 3,
        kelasId: 2,
      );
      expect(
        c.path,
        '/padi-masuk?limit=100&dari=2026-10-01&sampai=2026-10-27'
        '&pelanggan_id=3&kelas_padi_id=2',
      );
      expect(c.adaFilter, isTrue);
    });
  });
}
