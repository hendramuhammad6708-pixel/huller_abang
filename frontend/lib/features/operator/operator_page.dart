import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/konfirmasi_hapus.dart';
import '../../core/sesi.dart';
import '../../core/ui.dart';

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

  void _snack(String pesan, {bool galat = false}) =>
      tampilkanPesan(context, pesan, galat: galat);

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
    final ok = await konfirmasiHapus(
      context,
      judul: 'Hapus operator?',
      pesan: 'Akun "${op.nama}" (@${op.username}) akan dihapus permanen. '
          'Jika hanya ingin memblokir sementara, nonaktifkan saja.',
    );
    if (!ok || !mounted) return;
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
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Operator Baru'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          final aktif = c.items.where((o) => o.aktif).length;
          return RefreshIndicator(
            onRefresh: () => c.muat(paksa: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              children: [
                LebarKonten(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (c.memuat && c.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (c.galat != null)
                        BannerGalat(c.galat!,
                            onUlangi: () => c.muat(paksa: true))
                      else if (c.items.isEmpty)
                        KeadaanKosong(
                          icon: Icons.badge_rounded,
                          judul: 'Belum ada operator',
                          pesan: 'Buat akun untuk karyawan yang mencatat '
                              'padi masuk di huller.',
                          labelAksi: 'Tambah operator',
                          onAksi: () => _bukaForm(),
                        )
                      else ...[
                        JudulBagian('$aktif dari ${c.items.length} akun aktif'),
                        for (final op in c.items) ...[
                          _kartuOperator(op),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kartuOperator(Operator op) {
    final inisial = op.nama.isNotEmpty ? op.nama[0].toUpperCase() : '?';
    return KartuApp(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      onTap: () => _bukaForm(op: op),
      child: Row(
        children: [
          // Akun nonaktif tampil pudar agar mudah dibedakan
          Opacity(
            opacity: op.aktif ? 1 : 0.45,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppRadius.sedang),
              ),
              child: Text(inisial,
                  style: const TextStyle(
                      color: AppColors.mintText,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(op.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: op.aktif
                            ? AppColors.textDark
                            : AppColors.textMuted)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    op.aktif
                        ? const Lencana('Aktif')
                        : const Lencana('Nonaktif',
                            latar: AppColors.dangerSoft,
                            warna: AppColors.danger),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('@${op.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Tooltip(
            message: op.aktif ? 'Nonaktifkan akun' : 'Aktifkan akun',
            child: Switch(
              key: Key('toggle-${op.id}'),
              value: op.aktif,
              onChanged: (_) => _toggleAktif(op),
            ),
          ),
          PopupMenuButton<String>(
            key: Key('menu-operator-${op.id}'),
            tooltip: 'Pilihan',
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted),
            onSelected: (v) => switch (v) {
              'ubah' => _bukaForm(op: op),
              'reset' => _resetPassword(op),
              _ => _hapus(op),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'ubah',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Ubah data'),
                ]),
              ),
              PopupMenuItem(
                key: Key('reset-${op.id}'),
                value: 'reset',
                child: const Row(children: [
                  Icon(Icons.key_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Reset kata sandi'),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                key: Key('hapus-${op.id}'),
                value: 'hapus',
                child: const Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.danger),
                  SizedBox(width: 12),
                  Text('Hapus akun',
                      style: TextStyle(color: AppColors.danger)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Field kata sandi dengan tombol lihat/sembunyikan.
class _FieldSandi extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;

  const _FieldSandi(
      {required this.controller, required this.label, this.autofocus = false});

  @override
  State<_FieldSandi> createState() => _FieldSandiState();
}

class _FieldSandiState extends State<_FieldSandi> {
  bool _terlihat = false;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: !_terlihat,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: 'Minimal 6 karakter',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _terlihat ? 'Sembunyikan' : 'Lihat',
            onPressed: () => setState(() => _terlihat = !_terlihat),
            icon: Icon(_terlihat
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
          ),
        ),
        validator: (v) =>
            (v ?? '').length < 6 ? 'Kata sandi minimal 6 karakter' : null,
      );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_ubah ? 'Ubah Operator' : 'Operator Baru'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nama,
                  autofocus: !_ubah,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _username,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    helperText: 'Dipakai operator untuk login',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Username wajib diisi' : null,
                ),
                if (!_ubah) ...[
                  const SizedBox(height: 14),
                  _FieldSandi(controller: _password, label: 'Kata sandi'),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          key: const Key('btn-simpan-operator'),
          onPressed: _simpan,
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
      title: const Text('Reset Kata Sandi'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: _FieldSandi(
              controller: _sandi, label: 'Kata sandi baru', autofocus: true),
        ),
      ),
      actions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _sandi.text);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
