import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/sesi.dart';

/// Data akun operator dari API.
class Operator {
  final int id;
  final String nama;
  final String username;
  final bool aktif;

  const Operator({
    required this.id,
    required this.nama,
    required this.username,
    required this.aktif,
  });

  factory Operator.dariApi(Map<String, dynamic> j) => Operator(
        id: j['id'] as int,
        nama: j['nama'] as String,
        username: j['username'] as String,
        aktif: j['aktif'] == true,
      );
}

/// Kelola akun operator (owner only): daftar, tambah, ubah, reset password,
/// aktif/nonaktif, hapus — semua lewat /api/operators.
class OperatorController extends ChangeNotifier {
  final Sesi _sesi = Sesi.instance;

  List<Operator> _items = [];
  bool _memuat = false;
  String? _galat;

  List<Operator> get items => List.unmodifiable(_items);
  bool get memuat => _memuat;
  String? get galat => _galat;

  Future<void> muat({bool paksa = false}) async {
    if (_memuat || (_items.isNotEmpty && !paksa)) return;
    _memuat = true;
    _galat = null;
    notifyListeners();

    final jwb = await _sesi.api.get('/operators?limit=100');
    if (jwb.sukses && jwb.data is Map) {
      final items =
          (jwb.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      _items = items
          .whereType<Map<String, dynamic>>()
          .map(Operator.dariApi)
          .toList();
    } else {
      _galat = jwb.pesan;
    }

    _memuat = false;
    notifyListeners();
  }

  Future<void> tambah({
    required String nama,
    required String username,
    required String password,
  }) async {
    final jwb = await _sesi.api.post('/operators', {
      'nama': nama,
      'username': username,
      'password': password,
    });
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }

  Future<void> ubah(int id, {String? nama, String? username}) async {
    final body = <String, dynamic>{
      'nama': ?nama,
      'username': ?username,
    };
    final jwb = await _sesi.api.put('/operators/$id', body);
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }

  Future<void> resetPassword(int id, String passwordBaru) async {
    final jwb = await _sesi.api.put('/operators/$id', {
      'password': passwordBaru,
    });
    if (!jwb.sukses) throw jwb;
  }

  Future<void> setAktif(int id, bool aktif) async {
    final jwb = await _sesi.api.put('/operators/$id', {'aktif': aktif});
    if (!jwb.sukses) throw jwb;
    await muat(paksa: true);
  }

  Future<void> hapus(int id) async {
    final jwb = await _sesi.api.delete('/operators/$id');
    if (!jwb.sukses) throw jwb;
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

/// Halaman daftar operator (owner only; sudah dijaga route guard).
class OperatorPage extends StatefulWidget {
  const OperatorPage({super.key});

  @override
  State<OperatorPage> createState() => _OperatorPageState();
}

class _OperatorPageState extends State<OperatorPage> {
  final _controller = OperatorController();

  @override
  void initState() {
    super.initState();
    _controller.muat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String pesan, {bool galat = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            galat ? const Color(0xFFD64545) : AppColors.primary,
      ));
  }

  Future<void> _bukaForm({Operator? op}) async {
    final hasil = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _OperatorDialog(operator: op),
    );
    if (hasil == null || !mounted) return;
    try {
      if (op == null) {
        await _controller.tambah(
          nama: hasil['nama']!,
          username: hasil['username']!,
          password: hasil['password']!,
        );
        if (mounted) _snack('${hasil['nama']} ditambahkan');
      } else {
        await _controller.ubah(op.id,
            nama: hasil['nama'], username: hasil['username']);
        if (mounted) _snack('Data ${hasil['nama']} diperbarui');
      }
    } on ApiJawaban catch (e) {
      if (mounted) _snack(e.pesan, galat: true);
    }
  }

  Future<void> _resetPassword(Operator op) async {
    final sandi = await showDialog<String>(
      context: context,
      builder: (_) => const _ResetPasswordDialog(),
    );
    if (sandi == null || !mounted) return;
    try {
      await _controller.resetPassword(op.id, sandi);
      if (mounted) _snack('Kata sandi ${op.nama} direset');
    } on ApiJawaban catch (e) {
      if (mounted) _snack(e.pesan, galat: true);
    }
  }

  Future<void> _toggleAktif(Operator op) async {
    try {
      await _controller.setAktif(op.id, !op.aktif);
      if (mounted) {
        _snack(op.aktif
            ? '${op.nama} dinonaktifkan'
            : '${op.nama} diaktifkan');
      }
    } on ApiJawaban catch (e) {
      if (mounted) _snack(e.pesan, galat: true);
    }
  }

  Future<void> _hapus(Operator op) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_outline_rounded,
            size: 32, color: Color(0xFFD64545)),
        title: const Text('Hapus operator?',
            textAlign: TextAlign.center),
        content: Text(
          'Akun "${op.nama}" (${op.username}) akan dihapus permanen.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD64545)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _controller.hapus(op.id);
      if (mounted) _snack('${op.nama} dihapus');
    } on ApiJawaban catch (e) {
      if (mounted) _snack(e.pesan, galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-tambah-operator'),
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Operator Baru',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final c = _controller;
            return RefreshIndicator(
              onRefresh: () => c.muat(paksa: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                children: [
                  const Text(
                    'Akun Operator',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Kelola akun yang boleh mencatat penggilingan',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 18),
                  if (c.memuat)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child:
                          Center(child: CircularProgressIndicator()),
                    )
                  else if (c.galat != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAEA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFD64545)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(c.galat!,
                                  style: const TextStyle(
                                      color: Color(0xFFD64545)))),
                          TextButton(
                              onPressed: () => c.muat(paksa: true),
                              child: const Text('Ulangi')),
                        ],
                      ),
                    )
                  else if (c.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text('Belum ada operator. Tekan "Operator Baru".',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  else
                    for (final op in c.items) ...[
                      _kartuOperator(op),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _kartuOperator(Operator op) {
    final inisial = op.nama.isNotEmpty ? op.nama[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, Color(0xFF5CB88A)],
                  ),
                ),
                child: Text(inisial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(op.nama,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Text('@${op.username}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: op.aktif ? AppColors.mint : const Color(0xFFFFEAEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  op.aktif ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: op.aktif
                        ? AppColors.mintText
                        : const Color(0xFFD64545),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _bukaForm(op: op),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Ubah'),
              ),
              TextButton.icon(
                key: Key('reset-${op.id}'),
                onPressed: () => _resetPassword(op),
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('Reset Sandi'),
              ),
              TextButton.icon(
                key: Key('toggle-${op.id}'),
                onPressed: () => _toggleAktif(op),
                icon: Icon(
                    op.aktif
                        ? Icons.person_off_outlined
                        : Icons.person_outline,
                    size: 18),
                label: Text(op.aktif ? 'Nonaktifkan' : 'Aktifkan'),
              ),
              IconButton(
                key: Key('hapus-${op.id}'),
                tooltip: 'Hapus ${op.nama}',
                onPressed: () => _hapus(op),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: Color(0xFFD64545)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperatorDialog extends StatefulWidget {
  final Operator? operator;
  const _OperatorDialog({this.operator});

  @override
  State<_OperatorDialog> createState() => _OperatorDialogState();
}

class _OperatorDialogState extends State<_OperatorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.operator?.nama);
  late final _username =
      TextEditingController(text: widget.operator?.username);
  final _password = TextEditingController();

  bool get _ubah => widget.operator != null;

  @override
  void dispose() {
    _nama.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nama': _nama.text.trim(),
      'username': _username.text.trim(),
      if (!_ubah) 'password': _password.text,
    });
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title:
          Text(_ubah ? 'Ubah Operator' : 'Operator Baru'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama lengkap',
                  border: _border(AppColors.border),
                  enabledBorder: _border(AppColors.border),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Nama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _username,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Username (untuk login)',
                  border: _border(AppColors.border),
                  enabledBorder: _border(AppColors.border),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Username wajib diisi'
                    : null,
              ),
              if (!_ubah) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    helperText: 'Minimal 6 karakter',
                    border: _border(AppColors.border),
                    enabledBorder: _border(AppColors.border),
                  ),
                  validator: (v) => (v ?? '').length < 6
                      ? 'Kata sandi minimal 6 karakter'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          key: const Key('btn-simpan-operator'),
          onPressed: _simpan,
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog();

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sandi = TextEditingController();

  @override
  void dispose() {
    _sandi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Reset Kata Sandi'),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _sandi,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Kata sandi baru',
              helperText: 'Minimal 6 karakter',
            ),
            validator: (v) =>
                (v ?? '').length < 6 ? 'Minimal 6 karakter' : null,
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _sandi.text);
            }
          },
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
