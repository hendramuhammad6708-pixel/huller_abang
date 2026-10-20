import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/sesi.dart';

/// Ringkasan dashboard owner dari GET /api/dashboard/summary.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    final jwb = await Sesi.instance.api.get('/dashboard/summary');
    if (!mounted) return;
    setState(() {
      _memuat = false;
      if (jwb.sukses && jwb.data is Map) {
        _data = jwb.data as Map<String, dynamic>;
      } else {
        _galat = jwb.pesan;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muat,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Halo, ${Sesi.instance.user?.nama ?? ''} 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text('Ringkasan operasional huller hari ini',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 18),
              if (_memuat)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_galat != null)
                _galatBanner()
              else if (_data != null) ...[
                _KartuStatistik(
                  icon: Icons.inventory_2_rounded,
                  judul: 'Padi Masuk',
                  nilai: '0 kg',
                  catatan: 'Modul transaksi menyusul (Sprint 2)',
                ),
                const SizedBox(height: 12),
                _KartuStatistik(
                  icon: Icons.savings_outlined,
                  judul: 'Stok Upah',
                  nilai: '0 kg',
                  catatan: 'Terhitung otomatis dari transaksi giling',
                ),
                const SizedBox(height: 12),
                _KartuStatistik(
                  icon: Icons.account_balance_wallet_outlined,
                  judul: 'Saldo Titip',
                  nilai: '0 kg',
                  catatan: 'Saldo beras milik pelanggan',
                ),
                const SizedBox(height: 12),
                _KartuStatistik(
                  icon: Icons.point_of_sale_outlined,
                  judul: 'Penjualan',
                  nilai: '0',
                  catatan: 'Belum ada transaksi penjualan',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Master',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      _barisData('Total pelanggan',
                          '${_data!['total_pelanggan'] ?? 0}'),
                      _barisData('Petani',
                          '${(_data!['pelanggan_per_tipe']?['petani']) ?? 0}'),
                      _barisData('Pengepul',
                          '${(_data!['pelanggan_per_tipe']?['pengepul']) ?? 0}'),
                      _barisData(
                          'Milik huller',
                          '${(_data!['pelanggan_per_tipe']?['milik_huller']) ?? 0}'),
                      _barisData('Kelas padi',
                          '${_data!['total_kelas_padi'] ?? 0}'),
                      if (Sesi.instance.owner) ...[
                        const Divider(height: 20),
                        _barisData('Operator aktif',
                            '${_data!['operator_aktif'] ?? 0} / ${_data!['total_operator'] ?? 0}'),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _barisData(String label, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: AppColors.textMuted))),
            Text(nilai,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ],
        ),
      );

  Widget _galatBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEAEA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD64545)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(_galat!,
                    style: const TextStyle(color: Color(0xFFD64545)))),
            TextButton(onPressed: _muat, child: const Text('Ulangi')),
          ],
        ),
      );
}

class _KartuStatistik extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String nilai;
  final String catatan;

  const _KartuStatistik({
    required this.icon,
    required this.judul,
    required this.nilai,
    required this.catatan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: AppColors.mintText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(nilai,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(catatan,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
