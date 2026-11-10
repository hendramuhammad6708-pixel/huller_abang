import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/sesi.dart';
import 'core/ui.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/lainnya/lainnya_page.dart';
import 'features/operator/operator_page.dart';
import 'features/pelanggan/pages/daftar_pelanggan_page.dart';
import 'features/pelanggan/pelanggan_controller.dart';
import 'features/pengaturan/pengaturan_controller.dart';
import 'features/pengaturan/pengaturan_page.dart';
import 'features/penggilingan/padi_masuk_controller.dart';
import 'features/penggilingan/pages/form_padi_masuk_page.dart';
import 'features/penggilingan/penggilingan_page.dart';
import 'features/penjemuran/penjemuran_page.dart';
import 'features/penjemuran/penjemuran_service.dart';

/// Satu menu navigasi utama.
class _Menu {
  final IconData icon;
  final IconData iconAktif;
  final String label;
  final String subjudul;

  const _Menu(this.icon, this.iconAktif, this.label, this.subjudul);
}

const _menuDashboard = _Menu(
  Icons.dashboard_outlined,
  Icons.dashboard_rounded,
  'Dashboard',
  'Ringkasan operasional huller',
);
const _menuPadi = _Menu(
  Icons.grain_outlined,
  Icons.grain_rounded,
  'Padi Masuk',
  'Catat & lihat riwayat padi masuk',
);
const _menuPenjemuran = _Menu(
  Icons.wb_sunny_outlined,
  Icons.wb_sunny,
  'Penjemuran',
  'Mulai & selesaikan penjemuran',
);
const _menuPelanggan = _Menu(
  Icons.groups_outlined,
  Icons.groups_rounded,
  'Pelanggan',
  'Petani, pengepul & milik huller',
);
const _menuLainnya = _Menu(
  Icons.grid_view_outlined,
  Icons.grid_view_rounded,
  'Lainnya',
  'Operator, pengaturan & akun',
);

/// Indeks tab owner, dipakai pintasan dari Dashboard.
class TabOwner {
  static const dashboard = 0;
  static const padi = 1;
  static const penjemuran = 2;
  static const pelanggan = 3;
  static const lainnya = 4;
}

/// Kerangka utama setelah login: navigasi menyesuaikan role.
/// - Owner: Dashboard, Padi Masuk, Penjemuran, Pelanggan, Lainnya
/// - Operator: Padi Masuk dan Penjemuran
/// Layar sempit memakai bilah navigasi bawah, layar lebar memakai rail kiri.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _pelanggan = PelangganController();
  final _pengaturan = PengaturanController();
  final _padiMasuk = PadiMasukController();
  int _index = 0;

  @override
  void dispose() {
    _pelanggan.dispose();
    _pengaturan.dispose();
    _padiMasuk.dispose();
    super.dispose();
  }

  /// Buka form catat padi masuk langsung (mis. dari tombol di Dashboard).
  Future<void> _catatPadi() async {
    final pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPadiMasukPage(
          controller: _padiMasuk,
          pelanggan: _pelanggan,
          pengaturan: _pengaturan,
        ),
      ),
    );
    if (pesan != null && mounted) tampilkanPesan(context, pesan);
  }

  Future<void> _bukaHalaman(Widget halaman) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => halaman));

  Future<void> _bukaOperator() => _bukaHalaman(
    _halaman(
      'Operator',
      'Akun yang boleh mencatat penggilingan',
      const OperatorPage(),
    ),
  );

  Future<void> _bukaPengaturan() => _bukaHalaman(
    _halaman(
      'Pengaturan',
      'Bagi hasil, persentase & kelas padi',
      PengaturanPage(controller: _pengaturan),
    ),
  );

  /// Halaman tambahan tetap punya judul dan tombol kembali saat dibuka
  /// dari tab Lainnya atau pintasan Dashboard.
  Widget _halaman(String judul, String subjudul, Widget isi) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(judul),
          Text(
            subjudul,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ),
    body: isi,
  );

  Future<void> _keluar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          size: 32,
          color: AppColors.primary,
        ),
        title: const Text('Keluar dari aplikasi?', textAlign: TextAlign.center),
        content: const Text(
          'Anda perlu masuk lagi dengan username dan kata sandi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true) await Sesi.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final owner = Sesi.instance.owner;

    final penggilingan = PenggilinganPage(
      controller: _padiMasuk,
      pelanggan: _pelanggan,
      pengaturan: _pengaturan,
    );
    final penjemuran = PenjemuranPage(
      service: PenjemuranService(tokenGetter: () async => Sesi.instance.token),
      pelanggan: _pelanggan,
    );

    // Daftar menu dan halaman mengikuti role (urutan harus sama)
    final menu = owner
        ? const [
            _menuDashboard,
            _menuPadi,
            _menuPenjemuran,
            _menuPelanggan,
            _menuLainnya,
          ]
        : const [_menuPadi, _menuPenjemuran];
    final pages = owner
        ? <Widget>[
            DashboardPage(
              onCatatPadi: _catatPadi,
              onBukaTab: (i) => setState(() => _index = i),
              onBukaOperator: _bukaOperator,
              onBukaPengaturan: _bukaPengaturan,
            ),
            penggilingan,
            penjemuran,
            DaftarPelangganPage(controller: _pelanggan),
            LainnyaPage(
              onOperator: _bukaOperator,
              onPengaturan: _bukaPengaturan,
              onKeluar: _keluar,
            ),
          ]
        : <Widget>[penggilingan, penjemuran];

    // Jaga indeks tetap valid saat role berganti
    final index = _index < pages.length ? _index : 0;
    final aktif = menu[index];
    // NavigationBar butuh minimal 2 tujuan; operator cukup tanpa navigasi
    final adaNavigasi = menu.length > 1;
    final lebar = MediaQuery.sizeOf(context).width >= 840;

    final isi = IndexedStack(index: index, children: pages);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(aktif.label),
            Text(
              aktif.subjudul,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          _MenuAkun(onKeluar: _keluar),
          const SizedBox(width: 12),
        ],
      ),
      body: lebar && adaNavigasi
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.85,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: gradienHero,
                        borderRadius: BorderRadius.circular(AppRadius.sedang),
                      ),
                      child: const Icon(
                        Icons.grain_rounded,
                        color: AppColors.aksen,
                        size: 26,
                      ),
                    ),
                  ),
                  destinations: [
                    for (final m in menu)
                      NavigationRailDestination(
                        icon: Icon(m.icon),
                        selectedIcon: Icon(m.iconAktif),
                        label: Text(m.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: isi),
              ],
            )
          : isi,
      bottomNavigationBar: !lebar && adaNavigasi
          ? DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: [
                  for (final m in menu)
                    NavigationDestination(
                      icon: Icon(m.icon),
                      selectedIcon: Icon(m.iconAktif),
                      label: m.label,
                    ),
                ],
              ),
            )
          : null,
    );
  }
}

/// Avatar pengguna di kanan atas; ketuk untuk melihat akun dan keluar.
class _MenuAkun extends StatelessWidget {
  final VoidCallback onKeluar;

  const _MenuAkun({required this.onKeluar});

  @override
  Widget build(BuildContext context) {
    final user = Sesi.instance.user;
    final nama = user?.nama ?? '';
    final inisial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
    final role = (user?.owner ?? false) ? 'Pemilik' : 'Operator';

    return PopupMenuButton<String>(
      key: const Key('menu-akun'),
      tooltip: 'Akun',
      offset: const Offset(0, 52),
      onSelected: (v) {
        if (v == 'keluar') onKeluar();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nama,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${user?.username ?? ''} · $role',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'keluar',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: AppColors.danger),
              SizedBox(width: 12),
              Text('Keluar', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradienHero,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: AppShadows.kartu,
        ),
        child: Text(
          inisial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
