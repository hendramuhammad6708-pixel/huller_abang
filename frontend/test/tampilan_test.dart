import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huller_abang/core/app_theme.dart';
import 'package:huller_abang/core/ui.dart';
import 'package:huller_abang/features/auth/login_page.dart';
import 'package:huller_abang/features/dashboard/dashboard_page.dart';
import 'package:huller_abang/features/operator/operator_page.dart';
import 'package:huller_abang/features/pelanggan/models/pelanggan.dart';
import 'package:huller_abang/features/pelanggan/pages/daftar_pelanggan_page.dart';
import 'package:huller_abang/features/pelanggan/pages/form_pelanggan_page.dart';
import 'package:huller_abang/features/pelanggan/pelanggan_controller.dart';
import 'package:huller_abang/features/pelanggan/widgets/pelanggan_card.dart';
import 'package:huller_abang/features/pelanggan/widgets/tambah_pelanggan_dialog.dart';
import 'package:huller_abang/features/pengaturan/pengaturan_controller.dart';
import 'package:huller_abang/features/pengaturan/pengaturan_page.dart';
import 'package:huller_abang/features/penggilingan/models/padi_masuk.dart';
import 'package:huller_abang/features/penggilingan/padi_masuk_controller.dart';
import 'package:huller_abang/features/penggilingan/pages/form_padi_masuk_page.dart';
import 'package:huller_abang/features/penggilingan/pages/riwayat_padi_page.dart';
import 'package:huller_abang/features/penggilingan/widgets/padi_masuk_card.dart';

/// Render setiap halaman di layar HP kecil (360 px) dengan tema aplikasi.
/// Overflow tata letak akan membuat test gagal. Panggilan API di lingkungan
/// test selalu gagal, jadi tampilan galat ikut teruji.
void main() {
  Future<void> render(WidgetTester tester, Widget halaman,
      {Size ukuran = const Size(360, 740)}) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: halaman));
    await tester.pumpAndSettle();
  }

  Widget dalamDaftar(Widget anak) => Scaffold(
        body: ListView(padding: const EdgeInsets.all(20), children: [anak]),
      );

  group('tampilan HP kecil', () {
    testWidgets('login', (tester) async {
      await render(tester, const LoginPage());
      expect(find.text('HULLER ABANG'), findsOneWidget);
    });

    testWidgets('dashboard', (tester) async {
      await render(tester, DashboardPage(onCatatPadi: () {}, onBukaTab: (_) {}));
      expect(find.byKey(const Key('btn-catat-padi')), findsOneWidget);
    });

    testWidgets('daftar pelanggan', (tester) async {
      await render(tester, DaftarPelangganPage(controller: PelangganController()));
      expect(find.byKey(const Key('fab-tambah')), findsOneWidget);
    });

    testWidgets('form pelanggan (ubah)', (tester) async {
      await render(
        tester,
        FormPelangganPage(
          controller: PelangganController(),
          pelanggan: const Pelanggan(
              id: 1, nama: 'Pak Warsito', tipe: TipePelanggan.pengepul),
        ),
      );
      expect(find.byKey(const Key('btn-simpan')), findsOneWidget);
      // Form harus tampil di layar, tidak tertutup bilah tombol bawah
      expect(find.byKey(const Key('field-nama')), findsOneWidget);
      expect(tester.getSize(find.byType(BilahAksiBawah)).height, lessThan(200));
      final tipe = find.byKey(const Key('tipe-milik_huller'), skipOffstage: false);
      await tester.ensureVisible(tipe);
      await tester.tap(tipe);
      await tester.pump();
    });

    testWidgets('riwayat padi masuk', (tester) async {
      await render(
        tester,
        RiwayatPadiPage(
          controller: PadiMasukController(),
          pelanggan: PelangganController(),
          pengaturan: PengaturanController(),
        ),
      );
      expect(find.byKey(const Key('filter-tanggal')), findsOneWidget);
    });

    testWidgets('form padi masuk', (tester) async {
      await render(
        tester,
        FormPadiMasukPage(
          controller: PadiMasukController(),
          pelanggan: PelangganController(),
          pengaturan: PengaturanController(),
        ),
      );
      // Form harus tampil di layar, tidak tertutup bilah tombol bawah
      expect(find.byKey(const Key('field-pelanggan')), findsOneWidget);
      expect(tester.getSize(find.byType(BilahAksiBawah)).height, lessThan(200));
      // Validasi tampil tanpa merusak tata letak
      await tester.tap(find.byKey(const Key('btn-simpan')));
      await tester.pump();
      expect(find.text('Berat wajib diisi', skipOffstage: false), findsOneWidget);
    });

    testWidgets('dialog tambah pelanggan baru', (tester) async {
      await render(
        tester,
        TambahPelangganDialog(controller: PelangganController()),
      );
      expect(find.byKey(const Key('field-nama-pelanggan-baru')), findsOneWidget);
      expect(find.byKey(const Key('tipe-baru-milik_huller')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn-simpan-pelanggan-baru')));
      await tester.pump();
      expect(find.text('Nama wajib diisi'), findsOneWidget);
    });

    testWidgets('pengaturan', (tester) async {
      await render(tester, PengaturanPage(controller: PengaturanController()));
      expect(find.byKey(const Key('btn-simpan-persen')), findsOneWidget);
    });

    testWidgets('operator', (tester) async {
      await render(tester, const OperatorPage());
      expect(find.byKey(const Key('fab-tambah-operator')), findsOneWidget);
    });

    testWidgets('riwayat padi di layar desktop', (tester) async {
      await render(
        tester,
        RiwayatPadiPage(
          controller: PadiMasukController(),
          pelanggan: PelangganController(),
          pengaturan: PengaturanController(),
        ),
        ukuran: const Size(1280, 800),
      );
      // Konten dibatasi agar tidak melebar sepenuh layar
      final lebar = tester.getSize(find.byKey(const Key('filter-pelanggan'))).width;
      expect(lebar, lessThan(400));
    });

    testWidgets('kartu dengan teks panjang', (tester) async {
      await render(
        tester,
        dalamDaftar(Column(children: [
          PelangganCard(
            pelanggan: const Pelanggan(
              id: 1,
              nama: 'H. Muhammad Solihin Wijayakusuma Abdurrahman',
              kontak: '+6281234567890',
              tipe: TipePelanggan.milikHuller,
            ),
          ),
          PadiMasukCard(
            padi: PadiMasuk(
              id: 1,
              tanggal: DateTime(2026, 10, 27),
              pelangganId: 1,
              pelangganNama: 'H. Muhammad Solihin Wijayakusuma Abdurrahman',
              kelasId: 1,
              kelasNama: 'Pandan Wangi Super Premium',
              beratKg: 18650.75,
              catatan: 'Padi agak basah, dijemur ulang dua hari',
            ),
            onHapus: () {},
          ),
        ])),
      );
      expect(find.text('18.650,75 kg'), findsOneWidget);
    });
  });
}
