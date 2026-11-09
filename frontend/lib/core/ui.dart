import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Lebar maksimal konten agar tetap nyaman dibaca di tablet/desktop.
const lebarKontenMaks = 760.0;

/// Jarak kiri-kanan untuk daftar sliver: minimal 20, melebar di layar besar
/// sehingga konten tetap di tengah selebar [lebarKontenMaks].
double jarakSamping(double lebarTersedia) {
  final sisa = (lebarTersedia - lebarKontenMaks) / 2;
  return sisa > 20 ? sisa : 20;
}

/// Tampilkan snackbar sukses (gelap, ikon hijau) atau galat (merah).
void tampilkanPesan(BuildContext context, String pesan, {bool galat = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            galat ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: galat ? Colors.white : AppColors.primaryLight,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(pesan)),
        ],
      ),
      backgroundColor: galat ? AppColors.danger : AppColors.textDark,
    ));
}

/// Panel sorotan bergradasi hijau dengan ornamen lingkaran lembut
/// dan kilau kuning padi di pojok.
class PanelHero extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PanelHero(
      {super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    Widget bulatan(double ukuran, Color warna) => Container(
          width: ukuran,
          height: ukuran,
          decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
        );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: gradienHero,
        boxShadow: AppShadows.hero,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: bulatan(180, Colors.white.withValues(alpha: 0.07)),
          ),
          Positioned(
            bottom: -70,
            right: 60,
            child: bulatan(140, Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            top: -24,
            right: -24,
            child: bulatan(80, AppColors.aksen.withValues(alpha: 0.22)),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Membatasi lebar anak dan menaruhnya di tengah (layar lebar).
class LebarKonten extends StatelessWidget {
  final Widget child;
  final double maks;

  const LebarKonten({super.key, required this.child, this.maks = lebarKontenMaks});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        // Tinggi mengikuti anak; tanpa ini Align mengembang memenuhi ruang
        // (mis. di bottomNavigationBar akan menutupi seluruh halaman).
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maks),
          child: child,
        ),
      );
}

/// Kartu putih standar: sudut membulat, melayang dengan bayangan lembut.
class KartuApp extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const KartuApp({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sudut = BorderRadius.circular(AppRadius.besar);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: sudut, boxShadow: AppShadows.kartu),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: sudut,
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Ikon di dalam kotak berwarna lembut (aksen kartu).
class IkonKotak extends StatelessWidget {
  final IconData icon;
  final Color latar;
  final Color warna;
  final double ukuran;

  const IkonKotak(
    this.icon, {
    super.key,
    this.latar = AppColors.mint,
    this.warna = AppColors.mintText,
    this.ukuran = 44,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: ukuran,
        height: ukuran,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: latar,
          borderRadius: BorderRadius.circular(ukuran * 0.32),
        ),
        child: Icon(icon, size: ukuran * 0.52, color: warna),
      );
}

/// Label kecil berbentuk pil, mis. tipe pelanggan atau status akun.
class Lencana extends StatelessWidget {
  final String label;
  final Color latar;
  final Color warna;

  const Lencana(this.label,
      {super.key, this.latar = AppColors.mint, this.warna = AppColors.mintText});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: latar, borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: warna),
        ),
      );
}

/// Judul bagian di dalam halaman, opsional dengan aksi di kanan.
class JudulBagian extends StatelessWidget {
  final String teks;
  final Widget? aksi;

  const JudulBagian(this.teks, {super.key, this.aksi});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Garis aksen kecil hijau-kuning sebagai penanda bagian
            Container(
              width: 4,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryLight, AppColors.aksen],
                ),
              ),
            ),
            Expanded(
              child: Text(teks,
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                      color: AppColors.textDark)),
            ),
            ?aksi,
          ],
        ),
      );
}

/// Banner galat dengan tombol "Coba lagi".
class BannerGalat extends StatelessWidget {
  final String pesan;
  final VoidCallback? onUlangi;

  const BannerGalat(this.pesan, {super.key, this.onUlangi});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.sedang),
          border: Border.all(color: AppColors.dangerLine),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 20, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(pesan,
                  style: const TextStyle(color: AppColors.danger, height: 1.3)),
            ),
            if (onUlangi != null)
              TextButton(
                onPressed: onUlangi,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Coba lagi'),
              ),
          ],
        ),
      );
}

/// Tampilan saat daftar kosong: ikon, penjelasan, dan aksi yang disarankan.
class KeadaanKosong extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String? pesan;
  final String? labelAksi;
  final VoidCallback? onAksi;

  const KeadaanKosong({
    super.key,
    required this.icon,
    required this.judul,
    this.pesan,
    this.labelAksi,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IkonKotak(icon, ukuran: 64),
            const SizedBox(height: 16),
            Text(judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            if (pesan != null) ...[
              const SizedBox(height: 6),
              Text(pesan!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
            ],
            if (labelAksi != null && onAksi != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onAksi,
                icon: const Icon(Icons.add_rounded),
                label: Text(labelAksi!),
              ),
            ],
          ],
        ),
      );
}

/// Tombol aksi utama selebar layar dengan indikator memuat.
class TombolUtama extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool memuat;
  final String labelMemuat;

  const TombolUtama({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.memuat = false,
    this.labelMemuat = 'Menyimpan…',
  });

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: memuat ? null : onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: memuat
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon),
        label: Text(memuat ? labelMemuat : label),
      );
}

/// Area tombol yang menempel di bawah layar (tetap terlihat saat keyboard
/// terbuka), dipakai pada halaman form.
class BilahAksiBawah extends StatelessWidget {
  final List<Widget> children;

  const BilahAksiBawah({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: LebarKonten(
            maks: 640,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
