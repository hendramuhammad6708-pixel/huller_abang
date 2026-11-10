import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/sesi.dart';
import '../../core/ui.dart';
import '../../home_shell.dart';
import '../penggilingan/models/padi_masuk.dart';
import '../widgets/peringatan_card.dart';

/// Ringkasan dashboard owner dari GET /api/dashboard/summary.
class DashboardPage extends StatefulWidget {
  /// Dipanggil saat tombol "Catat Padi Masuk" diketuk (membuka form catat).
  final VoidCallback? onCatatPadi;

  /// Pindah ke tab lain di HomeShell (lihat [TabOwner]).
  final ValueChanged<int>? onBukaTab;

  const DashboardPage({super.key, this.onCatatPadi, this.onBukaTab});

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

    try {
      final jwb = await Sesi.instance.api.get('/dashboard/summary');
      if (!mounted) return;

      setState(() {
        _memuat = false;
        if (jwb.sukses && jwb.data is Map) {
          _data = Map<String, dynamic>.from(jwb.data as Map);
        } else {
          _galat = jwb.pesan;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _galat = 'Gagal memuat dashboard. Silakan coba lagi.';
      });
    }
  }

  String get _sapaan {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Selamat pagi';
    if (jam < 15) return 'Selamat siang';
    if (jam < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  int _angka(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  String _berat(dynamic v) {
    final n = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            LebarKonten(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sambutan(),
                  const SizedBox(height: 24),
                  if (_memuat)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_galat != null)
                    BannerGalat(_galat!, onUlangi: _muat)
                  else if (_data != null)
                    _ringkasan(_data!),
                  const SizedBox(height: 24),
                  const JudulBagian('Segera hadir'),
                  const _ModulMenyusul(
                    icon: Icons.savings_outlined,
                    judul: 'Stok Upah',
                    pesan: 'Dihitung otomatis dari transaksi giling',
                  ),
                  const SizedBox(height: 10),
                  const _ModulMenyusul(
                    icon: Icons.account_balance_wallet_outlined,
                    judul: 'Saldo Titip',
                    pesan: 'Saldo beras milik pelanggan',
                  ),
                  const SizedBox(height: 10),
                  const _ModulMenyusul(
                    icon: Icons.point_of_sale_outlined,
                    judul: 'Penjualan',
                    pesan: 'Pencatatan penjualan beras',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu sambutan dengan aksi utama harian.
  Widget _sambutan() {
    final nama = Sesi.instance.user?.nama ?? '';
    return PanelHero(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.aksen.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny_rounded,
                    size: 14, color: AppColors.primaryDark),
                const SizedBox(width: 6),
                Text(formatTanggal(DateTime.now()),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$_sapaan,',
            style: TextStyle(
                fontSize: 15, color: Colors.white.withValues(alpha: 0.85)),
          ),
          Text(
            nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text('Ada padi yang baru datang? Catat sekarang agar bagi hasil '
              'langsung terhitung.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
          if (widget.onCatatPadi != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('btn-catat-padi'),
              onPressed: widget.onCatatPadi,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(54),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle_rounded),
              label: const Text('Catat Padi Masuk'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ringkasan(Map<String, dynamic> d) {
    final tipe = d['pelanggan_per_tipe'] is Map
        ? d['pelanggan_per_tipe'] as Map
        : const {};
    final buka = widget.onBukaTab;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kartuPadi(d, buka),
        const SizedBox(height: 12),
        const PeringatanCard(
          judul: 'Informasi operasional',
          pesan: 'Pastikan data pelanggan dan kelas padi sudah tersedia '
              'sebelum mencatat padi masuk.',
        ),
        const SizedBox(height: 26),
        const JudulBagian('Data master'),
        _KartuAngka(
          icon: Icons.groups_rounded,
          judul: 'Pelanggan',
          nilai: '${_angka(d['total_pelanggan'])}',
          rincian: '${_angka(tipe['petani'])} petani · '
              '${_angka(tipe['pengepul'])} pengepul · '
              '${_angka(tipe['milik_huller'])} milik huller',
          onTap: buka == null ? null : () => buka(TabOwner.pelanggan),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KartuAngka(
                icon: Icons.category_rounded,
                judul: 'Kelas padi',
                nilai: '${_angka(d['total_kelas_padi'])}',
                latar: AppColors.goldSoft,
                warna: AppColors.gold,
                onTap: buka == null ? null : () => buka(TabOwner.pengaturan),
              ),
            ),
            if (Sesi.instance.owner) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _KartuAngka(
                  icon: Icons.badge_rounded,
                  judul: 'Operator aktif',
                  nilai: '${_angka(d['operator_aktif'])}'
                      '/${_angka(d['total_operator'])}',
                  latar: AppColors.blueSoft,
                  warna: AppColors.blue,
                  onTap: buka == null ? null : () => buka(TabOwner.operator),
                ),
              ),
            ],
          ],
        ),
        if (buka != null) ...[
          const SizedBox(height: 26),
          const JudulBagian('Akses cepat'),
          KartuApp(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _Pintasan(
                  icon: Icons.history_rounded,
                  label: 'Riwayat padi masuk',
                  onTap: () => buka(TabOwner.padi),
                ),
                const Divider(indent: 72),
                _Pintasan(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Jadwal penjemuran',
                  latar: AppColors.goldSoft,
                  warna: AppColors.gold,
                  onTap: () => buka(TabOwner.penjemuran),
                ),
                const Divider(indent: 72),
                _Pintasan(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Tambah pelanggan',
                  latar: AppColors.blueSoft,
                  warna: AppColors.blue,
                  onTap: () => buka(TabOwner.pelanggan),
                ),
                const Divider(indent: 72),
                _Pintasan(
                  icon: Icons.percent_rounded,
                  label: 'Atur bagi hasil',
                  latar: AppColors.goldSoft,
                  warna: AppColors.gold,
                  onTap: () => buka(TabOwner.pengaturan),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _kartuPadi(Map<String, dynamic> d, ValueChanged<int>? buka) {
    final pm = d['padi_masuk'] is Map ? d['padi_masuk'] as Map : const {};
    final hariIni =
        pm['hari_ini'] is Map ? pm['hari_ini'] as Map : const {};
    final total = pm['total_berat_kg'] ??
        d['total_berat_basah_kg'] ??
        d['total_berat_kg'] ??
        0;
    final jumlah = _angka(pm['jumlah_transaksi'] ?? d['transaksi']);
    final jumlahHariIni = _angka(hariIni['jumlah_transaksi']);
    final beratHariIni = _berat(hariIni['total_berat_kg']);

    return _KartuAngka(
      icon: Icons.inventory_2_rounded,
      judul: 'Padi masuk',
      nilai: '$jumlah transaksi',
      rincian: '${_berat(total)} kg total · '
          '$jumlahHariIni hari ini ($beratHariIni kg)',
      latar: AppColors.goldSoft,
      warna: AppColors.gold,
      onTap: buka == null ? null : () => buka(TabOwner.padi),
    );
  }
}

class _KartuAngka extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String nilai;
  final String? rincian;
  final Color latar;
  final Color warna;
  final VoidCallback? onTap;

  const _KartuAngka({
    required this.icon,
    required this.judul,
    required this.nilai,
    this.rincian,
    this.latar = AppColors.mint,
    this.warna = AppColors.mintText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teksNilai = Text(nilai,
        style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textDark));
    final teksJudul = Text(judul,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted));

    // Tanpa rincian: ubin tegak (dipakai berpasangan dalam satu baris)
    if (rincian == null) {
      return KartuApp(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IkonKotak(icon, latar: latar, warna: warna, ukuran: 40),
                const Spacer(),
                if (onTap != null)
                  const Icon(Icons.arrow_outward_rounded,
                      size: 18, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 14),
            teksNilai,
            teksJudul,
          ],
        ),
      );
    }

    return KartuApp(
      onTap: onTap,
      child: Row(
        children: [
          IkonKotak(icon, latar: latar, warna: warna, ukuran: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                teksJudul,
                teksNilai,
                Text(rincian!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Pintasan extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color latar;
  final Color warna;
  final VoidCallback onTap;

  const _Pintasan({
    required this.icon,
    required this.label,
    required this.onTap,
    this.latar = AppColors.mint,
    this.warna = AppColors.mintText,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: IkonKotak(icon, latar: latar, warna: warna, ukuran: 40),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textDark)),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

/// Modul yang belum tersedia, ditandai jelas agar tidak dikira data nol.
class _ModulMenyusul extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String pesan;

  const _ModulMenyusul(
      {required this.icon, required this.judul, required this.pesan});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.besar),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IkonKotak(icon,
                latar: AppColors.background,
                warna: AppColors.textMuted,
                ukuran: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  Text(pesan,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Lencana('Segera',
                latar: AppColors.goldSoft, warna: AppColors.gold),
          ],
        ),
      );
}
