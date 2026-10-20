import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../models/pelanggan.dart';

class PelangganCard extends StatelessWidget {
  final Pelanggan pelanggan;
  final VoidCallback? onTap;
  final VoidCallback? onUbah;
  final VoidCallback? onHapus;

  const PelangganCard({
    super.key,
    required this.pelanggan,
    this.onTap,
    this.onUbah,
    this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final p = pelanggan;
    final isPengepul = p.tipe == TipePelanggan.pengepul;
    final isMilikHuller = p.tipe == TipePelanggan.milikHuller;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
              _Avatar(inisial: p.inisial, pengepul: isPengepul, milikHuller: isMilikHuller),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            p.kontak.isEmpty ? 'Tanpa kontak' : p.kontak,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: p.tipe.label,
                          bg: isPengepul
                              ? AppColors.blueSoft
                              : isMilikHuller
                                  ? AppColors.mint.withValues(alpha: 0.6)
                                  : AppColors.mint,
                          fg: isPengepul
                              ? AppColors.blue
                              : isMilikHuller
                                  ? AppColors.primary
                                  : AppColors.mintText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hubungi ${p.nama}',
                onPressed: p.kontak.isEmpty
                    ? null
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Fitur telepon menyusul (nomor ${p.kontak})'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.mintText,
                ),
                icon: const Icon(Icons.call_rounded, size: 20),
              ),
              PopupMenuButton<String>(
                key: Key('menu-${p.id}'),
                tooltip: 'Menu',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted),
                onSelected: (v) => (v == 'ubah' ? onUbah : onHapus)?.call(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'ubah', child: Text('Ubah')),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String inisial;
  final bool pengepul;
  final bool milikHuller;
  const _Avatar(
      {required this.inisial, required this.pengepul, required this.milikHuller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pengepul
              ? const [Color(0xFF3B6FD8), Color(0xFF6C93E8)]
              : milikHuller
                  ? const [Color(0xFF8A7A3D), Color(0xFFC9A227)]
                  : const [AppColors.primaryLight, Color(0xFF5CB88A)],
        ),
      ),
      child: Text(
        inisial,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
