import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/sesi.dart';

/// Halaman login pertama aplikasi. Setelah berhasil, [Sesi] sudah terisi
/// dan halaman pemanggil (main.dart) akan menampilkan HomeShell.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _sedangKirim = false;
  String? _galat;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sedangKirim = true;
      _galat = null;
    });
    try {
      await Sesi.instance.login(_username.text.trim(), _password.text);
      // Sukses: main.dart otomatis menampilkan HomeShell (ListenableBuilder).
    } on ApiJawaban catch (e) {
      setState(() => _galat = e.status == 0
          ? e.pesan
          : (e.pesan.isEmpty ? 'Username atau kata sandi salah.' : e.pesan));
    } finally {
      if (mounted) setState(() => _sedangKirim = false);
    }
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color(0xFF0F3328)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.grain_rounded,
                        size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HULLER ABANG',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sistem Manajemen Produksi Padi',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Masuk',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 18),
                          if (_galat != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEAEA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_galat!,
                                  style: const TextStyle(
                                      color: Color(0xFFD64545), fontSize: 13)),
                            ),
                          ],
                          TextFormField(
                            key: const Key('field-username'),
                            controller: _username,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: AppColors.background,
                              border: _border(AppColors.border),
                              enabledBorder: _border(AppColors.border),
                              focusedBorder: _border(AppColors.primaryLight, 1.5),
                            ),
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Username wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('field-password'),
                            controller: _password,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _masuk(),
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: AppColors.background,
                              border: _border(AppColors.border),
                              enabledBorder: _border(AppColors.border),
                              focusedBorder: _border(AppColors.primaryLight, 1.5),
                            ),
                            validator: (v) => (v ?? '').isEmpty
                                ? 'Kata sandi wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const Key('btn-masuk'),
                            onPressed: _sedangKirim ? null : _masuk,
                            icon: _sedangKirim
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(_sedangKirim
                                ? 'Memproses…'
                                : 'Masuk'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Lupa kata sandi? Hubungi pemilik huller.',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
