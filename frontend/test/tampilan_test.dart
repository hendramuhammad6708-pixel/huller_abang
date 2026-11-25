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
import 'package:huller_abang/features/pelanggan/riwayat_transaksi_controller.dart';
import 'package:huller_abang/features/pelanggan/pages/detail_pelanggan_page.dart';
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
  Future<void> render(
    WidgetTester tester,
    Widget halaman, {
    Size ukuran = const Size(360, 740),
  }) async {
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
      await render(
        tester,
        DashboardPage(onCatatPadi: () {}, onBukaTab: (_) {}),
      );
      expect(find.byKey(const Key('btn-catat-padi')), findsOneWidget);
    });

    testWidgets('daftar pelanggan', (tester) async {
      await render(
        tester,
        DaftarPelangganPage(controller: PelangganController()),
      );
      expect(find.byKey(const Key('fab-tambah')), findsOneWidget);
    });

    testWidgets('detail pelanggan menampilkan riwayat transaksi', (
      tester,
    ) async {
      await render(
        tester,
        DetailPelangganPage(
          pelanggan: const Pelanggan(
            id: 1,
            nama: 'Pak Budi',
            tipe: TipePelanggan.petani,
          ),
          pelangganController: PelangganController(),
          riwayatController: RiwayatTransaksiController(1),
        ),
      );
      expect(find.text('Riwayat transaksi'), findsOneWidget);
      expect(find.byKey(const Key('riwayat-total-transaksi')), findsOneWidget);
      expect(find.byKey(const Key('btn-ubah-pelanggan')), findsOneWidget);
      expect(find.byKey(const Key('btn-hapus-pelanggan')), findsOneWidget);
    });

    testWidgets('form pelanggan (ubah)', (tester) async {
      await render(
        tester,
        FormPelangganPage(
          controller: PelangganController(),
          pelanggan: const Pelanggan(
            id: 1,
            nama: 'Pak Warsito',
            tipe: TipePelanggan.pengepul,
          ),
        ),
      );
      expect(find.byKey(const Key('btn-simpan')), findsOneWidget);
      // Form harus tampil di layar, tidak tertutup bilah tombol bawah
      expect(find.byKey(const Key('field-nama')), findsOneWidget);
      expect(tester.getSize(find.byType(BilahAksiBawah)).height, lessThan(200));
      final tipe = find.byKey(
        const Key('tipe-milik_huller'),
        skipOffstage: false,
      );
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

      // Label filter ringkas ("Pelanggan"/"Kelas") sejajar vertikal dengan
      // kotaknya, tidak menempel di tepi atas
      for (final (kunci, label) in [
        ('filter-pelanggan', 'Pelanggan'),
        ('filter-kelas', 'Kelas'),
      ]) {
        final kotak = tester.getCenter(find.byKey(Key(kunci)));
        final teks = tester.getCenter(find.text(label));
        expect(
          (teks.dy - kotak.dy).abs(),
          lessThan(4),
          reason: 'label $label tidak di tengah kotak',
        );
      }
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
      // Tanpa sesi owner (setara operator) tombol tambah pelanggan tetap ada
      expect(
        find.byKey(const Key('btn-tambah-pelanggan-baru'), skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(BilahAksiBawah)).height, lessThan(200));
      // Nama tombol utuh, bukan "& Lagi"/"Simpan & Lagi"
      expect(find.text('Simpan & Catat Lagi'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      // Dua tombol simpan berukuran sama (dulu "Simpan" dua kali lebih lebar)
      final simpan = tester.getSize(find.byKey(const Key('btn-simpan')));
      final lagi = tester.getSize(find.byKey(const Key('btn-simpan-lagi')));
      expect((simpan.width - lagi.width).abs(), lessThan(1));
      expect((simpan.height - lagi.height).abs(), lessThan(1));
      // Validasi tampil tanpa merusak tata letak
      await tester.tap(find.byKey(const Key('btn-simpan')));
      await tester.pump();
      expect(
        find.text('Berat wajib diisi', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('form padi masuk: tombol simpan tetap di atas keyboard', (
      tester,
    ) async {
      await render(
        tester,
        FormPadiMasukPage(
          controller: PadiMasukController(),
          pelanggan: PelangganController(),
          pengaturan: PengaturanController(),
        ),
      );
      final tanpaKeyboard = tester.getRect(find.byKey(const Key('btn-simpan')));
      expect(tanpaKeyboard.bottom, greaterThan(600));

      // Keyboard setinggi 300 px terbuka: tombol harus naik, bukan tertutup
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final denganKeyboard = tester.getRect(
        find.byKey(const Key('btn-simpan')),
      );
      expect(denganKeyboard.bottom, lessThanOrEqualTo(740 - 300));
      expect(find.byKey(const Key('btn-simpan-lagi')), findsOneWidget);
    });

    testWidgets('dialog tambah pelanggan baru', (tester) async {
      await render(
        tester,
        TambahPelangganDialog(controller: PelangganController()),
      );
      expect(
        find.byKey(const Key('field-nama-pelanggan-baru')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tipe-baru-milik_huller')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn-simpan-pelanggan-baru')));
      await tester.pump();
      expect(find.text('Nama wajib diisi'), findsOneWidget);
    });

    testWidgets('pengaturan', (tester) async {
      await render(tester, PengaturanPage(controller: PengaturanController()));
      expect(find.byKey(const Key('btn-simpan-persen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn-simpan-persen')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dialog-konfirmasi-pengaturan')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Mengubah persentase hanya akan berlaku untuk transaksi baru. '
          'Transaksi yang sudah ada tidak akan berubah.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('btn-ya-simpan')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn-batal-pengaturan')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dialog-konfirmasi-pengaturan')),
        findsNothing,
      );
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
      final lebar = tester
          .getSize(find.byKey(const Key('filter-pelanggan')))
          .width;
      expect(lebar, lessThan(400));
    });

    testWidgets('kartu dengan teks panjang', (tester) async {
      await render(
        tester,
        dalamDaftar(
          Column(
            children: [
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
                onCetak: () {},
                onBagikan: () {},
                onVoid: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('18.650,75 kg'), findsOneWidget);
      // Kelas dan catatan tampil utuh (tidak terpotong "K…"/"gaha…" seperti dulu
      // saat tiga ikon aksi berbagi baris dengan berat)
      expect(find.text('Pandan Wangi Super Premium'), findsOneWidget);
      expect(
        find.text('Padi agak basah, dijemur ulang dua hari'),
        findsOneWidget,
      );
      // Aksi ada di menu "⋮"; belum terlihat sebelum dibuka
      expect(find.byKey(const Key('btn-cetak-1')), findsNothing);
      await tester.tap(find.byKey(const Key('btn-menu-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('btn-cetak-1')), findsOneWidget);
      expect(find.byKey(const Key('btn-bagikan-1')), findsOneWidget);
      expect(find.byKey(const Key('btn-void-1')), findsOneWidget);
    });

    testWidgets(
      'kartu menampilkan status, dan selesai giling tidak bisa dibatalkan',
      (tester) async {
        PadiMasuk padi(int id, String status) => PadiMasuk(
          id: id,
          tanggal: DateTime(2026, 10, 27),
          pelangganId: 1,
          pelangganNama: 'Pak Budi',
          kelasId: 1,
          kelasNama: 'Kelas 1',
          beratKg: 100,
          status: status,
        );

        await render(
          tester,
          dalamDaftar(
            Column(
              children: [
                for (final (id, status) in [
                  (1, 'masuk'),
                  (2, 'dijemur'),
                  (3, 'siap_giling'),
                  (4, 'selesai_giling'),
                ])
                  PadiMasukCard(
                    padi: padi(id, status),
                    onCetak: () {},
                    onBagikan: () {},
                    onVoid: () {},
                  ),
              ],
            ),
          ),
        );

        expect(find.text('Masuk'), findsOneWidget);
        expect(find.text('Dijemur'), findsOneWidget);
        expect(find.text('Siap Giling'), findsOneWidget);
        expect(find.text('Selesai Giling'), findsOneWidget);

        // Selesai giling: menu hanya cetak dan bagikan (server menolak void)
        await tester.tap(find.byKey(const Key('btn-menu-4')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('btn-cetak-4')), findsOneWidget);
        expect(find.byKey(const Key('btn-void-4')), findsNothing);
      },
    );

    testWidgets('kartu void tidak punya aksi cetak atau bagikan', (
      tester,
    ) async {
      await render(
        tester,
        dalamDaftar(
          PadiMasukCard(
            padi: PadiMasuk(
              id: 9,
              nomorTransaksi: 'PM-20261124-0009',
              tanggal: DateTime(2026, 11, 24),
              pelangganId: 1,
              pelangganNama: 'Pak Budi',
              kelasId: 1,
              kelasNama: 'Kelas 1',
              beratKg: 100,
              status: 'void',
              voidReason: 'Dibatalkan',
            ),
            onCetak: () {},
            onBagikan: () {},
            onVoid: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('btn-cetak-9')), findsNothing);
      expect(find.byKey(const Key('btn-bagikan-9')), findsNothing);
      expect(find.byKey(const Key('btn-void-9')), findsNothing);
      expect(find.text('VOID'), findsOneWidget);
    });
  });
}
