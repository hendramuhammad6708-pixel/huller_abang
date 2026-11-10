import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/sesi.dart';
import '../../core/ui.dart';

/// Menu owner yang tidak termasuk navigasi utama: akun operator, pengaturan
/// bagi hasil/kelas padi, dan aksi keluar.
class LainnyaPage extends StatelessWidget {
  final VoidCallback onOperator;
  final VoidCallback onPengaturan;
  final VoidCallback onKeluar;

  const LainnyaPage({
    super.key,
    required this.onOperator,
    required this.onPengaturan,
    required this.onKeluar,
  });

  @override
  Widget build(BuildContext context) {
    final user = Sesi.instance.user;
    final nama = user?.nama ?? 'Pengguna';
    final username = user?.username ?? '';
    final inisial = nama.isEmpty ? '?' : nama[0].toUpperCase();
    final role = (user?.owner ?? false) ? 'Pemilik huller' : 'Operator';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        LebarKonten(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelHero(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        inisial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            username.isEmpty ? role : '@$username',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Lencana(
                            role,
                            latar: Colors.white.withValues(alpha: 0.18),
                            warna: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const JudulBagian('Kelola huller'),
              KartuApp(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _MenuTile(
                      key: const Key('menu-lainnya-operator'),
                      icon: Icons.badge_outlined,
                      judul: 'Operator',
                      keterangan: 'Tambah, ubah, dan atur akses operator',
                      onTap: onOperator,
                    ),
                    const Divider(indent: 72),
                    _MenuTile(
                      key: const Key('menu-lainnya-pengaturan'),
                      icon: Icons.tune_rounded,
                      judul: 'Pengaturan',
                      keterangan: 'Bagi hasil, persentase, dan kelas padi',
                      latar: AppColors.goldSoft,
                      warna: AppColors.gold,
                      onTap: onPengaturan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const JudulBagian('Bantuan'),
              const KartuApp(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IkonKotak(
                      Icons.support_agent_rounded,
                      latar: AppColors.blueSoft,
                      warna: AppColors.blue,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Butuh bantuan?',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hubungi pemilik huller untuk reset kata sandi '
                            'atau kendala data.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const Key('btn-keluar-lainnya'),
                onPressed: onKeluar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari akun'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String keterangan;
  final Color latar;
  final Color warna;
  final VoidCallback onTap;

  const _MenuTile({
    super.key,
    required this.icon,
    required this.judul,
    required this.keterangan,
    required this.onTap,
    this.latar = AppColors.mint,
    this.warna = AppColors.mintText,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: IkonKotak(icon, latar: latar, warna: warna, ukuran: 40),
    title: Text(
      judul,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    ),
    subtitle: Text(
      keterangan,
      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
