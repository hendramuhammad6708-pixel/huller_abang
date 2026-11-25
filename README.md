# Huller Abang - Sistem Manajemen Produksi Padi

Aplikasi untuk mencatat padi masuk, penjemuran, dan bagi hasil di huller.
Backend Laravel (API JSON) di `backend/`, aplikasi Flutter di `frontend/`.

## Kebutuhan
- PHP 8.4 (minimal 8.3), Composer, MySQL 8, Node.js (hanya untuk build aset Vite).
- Flutter (channel stable) dan Android SDK bila menjalankan di HP/emulator.

## Menjalankan backend
Semua perintah dari folder `backend/`.

1. Buat database kosong `huller_abang` (dan `huller_abang_test` untuk menjalankan test).
2. `composer setup` — menginstal dependensi, menyalin `.env.example` ke `.env`, membuat `APP_KEY`, menjalankan migrasi, lalu `npm install` dan `npm run build`.
3. Isi `OWNER_PASSWORD` (dan bila perlu `OWNER_USERNAME`, bawaannya `owner`) di `.env`, lalu `php artisan db:seed` untuk akun owner, kelas padi, dan persentase bawaan. Owner tidak dibuat bila kata sandi kosong.
4. Jalankan server: `php artisan serve --host=0.0.0.0 --port=8000` (atau `composer dev`). Cek `GET /api/health`.

Pengaturan penting di `.env`: `APP_TIMEZONE` (bawaan `Asia/Jakarta`) dan `SANCTUM_EXPIRATION` (masa berlaku token dalam menit, bawaan 10080 = 7 hari).

Test: `vendor/bin/pint --test` lalu `php artisan test` (butuh MySQL `huller_abang_test`).

## Menjalankan aplikasi Flutter
Dari folder `frontend/`:

```
flutter pub get
flutter run --dart-define=API_URL=http://<alamat-backend>:8000/api
```

- Emulator Android: alamat bawaan `http://10.0.2.2:8000/api` sudah mengarah ke komputer Anda.
- HP lewat kabel USB dengan backend di `localhost`: jalankan `adb reverse tcp:8000 tcp:8000`, lalu `--dart-define=API_URL=http://localhost:8000/api`.
- HP lewat Wi-Fi: jalankan backend dengan `--host=0.0.0.0` dan pakai IP komputer di `API_URL`.
- Build release wajib memakai alamat HTTPS; HTTP tanpa enkripsi hanya diizinkan pada build debug/profile.

Test: `flutter analyze` lalu `flutter test`.

## Hak akses
| | Owner | Operator |
|---|---|---|
| Padi masuk, penjemuran, bagi hasil | ya | ya |
| Lihat daftar pelanggan, kelas padi, pengaturan | ya | ya |
| Tambah pelanggan | semua tipe | hanya petani dan pengepul |
| Ubah/hapus pelanggan, riwayat transaksi pelanggan | ya | tidak |
| Kelola operator, pengaturan persentase, kelas padi, dashboard lengkap | ya | tidak |

Akun operator yang dinonaktifkan atau dihapus langsung kehilangan semua sesinya.

## Konvensi API (disepakati di Sprint Planning)
- Semua endpoint berawalan `/api`, memakai JSON, dan butuh header `Authorization: Bearer <token>` kecuali `/health` dan `/login`.
- Sukses: `{ "success": true, "message": "...", "data": ... }`
- Gagal: `{ "success": false, "message": "...", "errors": [{ "field": "...", "message": "..." }] }`
- Daftar memakai pagination: `page`, `limit` (maksimal 100), hasil `data.items` + `data.meta.total`.
- Kode status: 401 token tidak ada/kedaluwarsa, 403 role tidak berhak, 404 tidak ditemukan, 409 melanggar urutan status, 422 isian tidak valid, 429 terlalu banyak percobaan login.
- Dokumentasi per modul ada di [docs/api/](docs/api/).

## Alur status padi
`masuk` → `dijemur` → `siap_giling` → `selesai_giling`. Transaksi bisa dibatalkan (`void`) selama belum selesai giling. Lama jemur, persen susut, dan penanda "terlalu lama" dihitung di backend.

## Git dan CI
- `main` adalah branch stabil, `develop` untuk integrasi. Kerjakan fitur di branch topik lalu buka pull request.
- GitHub Actions (`backend-laravel` dan `frontend-flutter`) berjalan pada setiap push dan pull request ke `main` dan `develop`: Pint, `php artisan test`, `flutter analyze`, `flutter test`. Jalankan perintah yang sama di komputer sebelum push, dan pastikan semua file baru sudah di-`git add`.
- Pesan commit dan identifier memakai bahasa Indonesia.
