import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/sesi.dart';
import '../../core/ui.dart';

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
  bool _sandiTerlihat = false;
  String? _galat;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
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

  @override
  Widget build(BuildContext context) {
    Widget bulatan(double ukuran, Color warna) => Container(
          width: ukuran,
          height: ukuran,
          decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
        );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16A34A), AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            // Ornamen latar: lingkaran transparan dan kilau kuning padi
            Positioned(
                top: -90,
                right: -70,
                child: bulatan(260, Colors.white.withValues(alpha: 0.07))),
            Positioned(
                top: 40,
                right: 30,
                child: bulatan(70, AppColors.aksen.withValues(alpha: 0.35))),
            Positioned(
                bottom: -120,
                left: -80,
                child: bulatan(300, Colors.white.withValues(alpha: 0.05))),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: LebarKonten(
                    maks: 420,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.grain_rounded,
                              size: 40, color: AppColors.aksen),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'HULLER ABANG',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sistem Manajemen Produksi Padi',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 32),
                        _kartuForm(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.help_outline_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Lupa kata sandi? Hubungi pemilik huller.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Selamat datang',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('Masuk dengan akun yang diberikan pemilik huller.',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              if (_galat != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.kecil),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 20, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_galat!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13.5)),
                      ),
                    ],
                  ),
                ),
              ],
              TextFormField(
                key: const Key('field-username'),
                controller: _username,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  fillColor: AppColors.background,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Username wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('field-password'),
                controller: _password,
                obscureText: !_sandiTerlihat,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _masuk(),
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  fillColor: AppColors.background,
                  suffixIcon: IconButton(
                    tooltip: _sandiTerlihat
                        ? 'Sembunyikan kata sandi'
                        : 'Lihat kata sandi',
                    onPressed: () =>
                        setState(() => _sandiTerlihat = !_sandiTerlihat),
                    icon: Icon(_sandiTerlihat
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Kata sandi wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              TombolUtama(
                key: const Key('btn-masuk'),
                label: 'Masuk',
                icon: Icons.login_rounded,
                labelMemuat: 'Memproses…',
                memuat: _sedangKirim,
                onPressed: _masuk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
