import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/sesi.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/operator/operator_page.dart';
import 'features/pelanggan/pages/daftar_pelanggan_page.dart';
import 'features/pelanggan/pelanggan_controller.dart';
import 'features/pengaturan/pengaturan_controller.dart';
import 'features/pengaturan/pengaturan_page.dart';
import 'features/penggilingan/penggilingan_page.dart';

/// Kerangka utama setelah login: navigasi menyesuaikan role.
/// - Owner: Dashboard, Pelanggan, Operator, Pengaturan, Penggilingan
/// - Operator: hanya Penggilingan (modul lain menyusul)
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _pelanggan = PelangganController();
  final _pengaturan = PengaturanController();
  int _index = 0;

  @override
  void dispose() {
    _pelanggan.dispose();
    _pengaturan.dispose();
    super.dispose();
  }

  Future<void> _keluar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.logout_rounded, size: 32),
        title: const Text('Keluar?', textAlign: TextAlign.center),
        content: const Text('Anda akan keluar dari aplikasi.',
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

    // Daftar tab mengikuti role
    final destinations = owner
        ? const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Pelanggan'),
            NavigationDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge_rounded),
                label: 'Operator'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Pengaturan'),
            NavigationDestination(
                icon: Icon(Icons.grain_outlined),
                selectedIcon: Icon(Icons.grain_rounded),
                label: 'Penggilingan'),
          ]
        : const [
            NavigationDestination(
                icon: Icon(Icons.grain_outlined),
                selectedIcon: Icon(Icons.grain_rounded),
                label: 'Penggilingan'),
          ];

    final pages = owner
        ? <Widget>[
            const DashboardPage(),
            DaftarPelangganPage(controller: _pelanggan),
            const OperatorPage(),
            PengaturanPage(controller: _pengaturan),
            const PenggilinganPage(),
          ]
        : <Widget>[
            const PenggilinganPage(),
          ];

    // Jaga indeks tetap valid saat role berganti
    final index = _index < pages.length ? _index : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          destinations[index].label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                Sesi.instance.user?.nama ?? '',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: _keluar,
            icon: const Icon(Icons.logout_rounded, size: 21),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        destinations: destinations,
      ),
    );
  }
}
