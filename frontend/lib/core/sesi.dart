import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Pengguna yang sedang masuk (hasil POST /api/login atau GET /api/me).
class Pengguna {
  final int id;
  final String nama;
  final String username;
  final String role; // 'owner' | 'operator'
  final bool aktif;

  const Pengguna({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    required this.aktif,
  });

  bool get owner => role == 'owner';

  factory Pengguna.dariJson(Map<String, dynamic> j) => Pengguna(
        id: j['id'] as int,
        nama: j['nama'] as String,
        username: j['username'] as String,
        role: j['role'] as String,
        aktif: j['aktif'] == true,
      );
}

/// Status sesi aplikasi. Token disimpan di SharedPreferences agar tetap
/// login setelah aplikasi dibuka ulang.
class Sesi extends ChangeNotifier {
  Sesi._();
  static final Sesi instance = Sesi._();

  final ApiClient api = ApiClient();

  Pengguna? _user;
  bool _memuat = true;

  Pengguna? get user => _user;
  String? get token => api.token;
  bool get sudahLogin => _user != null;
  bool get owner => _user?.owner ?? false;
  bool get memuat => _memuat;

  /// Pulihkan sesi tersimpan; panggil sekali saat aplikasi dibuka.
  Future<void> mulai() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      _memuat = false;
      notifyListeners();
      return;
    }
    api.token = token;
    final jwb = await api.get('/me');
    if (jwb.sukses && jwb.data is Map) {
      _user = Pengguna.dariJson(jwb.data as Map<String, dynamic>);
    } else {
      await _buangSesi();
    }
    _memuat = false;
    notifyListeners();
  }

  /// Login; lempar [ApiJawaban] gagal (kredensial salah / akun nonaktif).
  Future<void> login(String username, String password) async {
    final jwb = await api.post('/login', {
      'username': username,
      'password': password,
    });
    if (!jwb.sukses || jwb.data is! Map) {
      throw jwb;
    }
    final data = jwb.data as Map<String, dynamic>;
    api.token = data['token'] as String;
    _user = Pengguna.dariJson(data['user'] as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', api.token!);
    notifyListeners();
  }

  Future<void> logout() async {
    // Cabut token di server (diabaikan jika sudah kadaluarsa)
    if (api.token != null) await api.post('/logout');
    await _buangSesi();
    notifyListeners();
  }

  Future<void> _buangSesi() async {
    api.token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
