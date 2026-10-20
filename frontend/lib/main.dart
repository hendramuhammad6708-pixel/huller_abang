import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/sesi.dart';
import 'features/auth/login_page.dart';
import 'home_shell.dart';

void main() {
  // Pulihkan sesi tersimpan (token + profil) sebelum menampilkan UI
  Sesi.instance.mulai();
  runApp(const HullerAbangApp());
}

class HullerAbangApp extends StatelessWidget {
  const HullerAbangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huller Abang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: Sesi.instance,
        builder: (context, _) {
          final sesi = Sesi.instance;
          // Masih memulihkan sesi: tampilkan splash singkat
          if (sesi.memuat) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return sesi.sudahLogin ? const HomeShell() : const LoginPage();
        },
      ),
    );
  }
}
