# API Autentikasi

Dasar alamat: `http://localhost:8000/api`
Kirim header `Accept: application/json` (dan `Content-Type: application/json` untuk POST).

Format respons sama dengan modul lain: `{ "success", "message", "data" }`, dan `errors` pada `422`.

## POST /api/login

Body: `{ "username": "owner", "password": "rahasia123" }`

Respons `200`:
```json
{ "success": true, "message": "Berhasil masuk",
  "data": { "token": "1|abc…", "token_type": "Bearer",
            "user": { "id": 1, "nama": "Pemilik", "username": "owner", "role": "owner", "aktif": true } } }
```

| Kode | Arti |
|---|---|
| 401 | Username atau kata sandi salah |
| 403 | Akun nonaktif |
| 422 | Isian kosong |
| 429 | Terlalu banyak percobaan |

**Pembatasan:** maksimal 5 percobaan per menit untuk satu username dari satu IP, dan 20 per menit per IP. Respons `429` berisi header `Retry-After` (detik).

## Masa berlaku token
- Token berlaku `SANCTUM_EXPIRATION` menit (bawaan 10080 = 7 hari). Setelah itu setiap permintaan dijawab `401`.
- Token dicabut saat: logout, akun operator dinonaktifkan, kata sandinya diganti, atau akunnya dihapus.
- Akun yang dinonaktifkan ditolak `401` ("Akun nonaktif. Hubungi Pemilik.") walau tokennya masih ada.
- Aplikasi Flutter menanggapi `401` dengan kembali ke halaman login.

## POST /api/logout
Butuh token. Mencabut token yang sedang dipakai. Tetap bisa dipanggil walau akun sudah dinonaktifkan. Respons `200`.

## GET /api/me
Butuh token dan akun aktif. Respons `200`: `data` berisi `id, nama, username, role, aktif`.

## GET /api/health
Publik. Respons `200` bila server dan database hidup, `500` bila database tidak terhubung.

## GET /api/dashboard/summary
Butuh token (owner dan operator). `data` berisi:
`total_operator`, `operator_aktif`, `total_pelanggan`, `pelanggan_per_tipe` (`pengepul`, `petani`, `milik_huller`), `total_kelas_padi`, `total_pengaturan`,
`padi_masuk` (`jumlah_transaksi`, `total_berat_kg`, `hari_ini` { `jumlah_transaksi`, `total_berat_kg` }),
`penjemuran` (`sedang_dijemur`, `siap_giling`), `transaksi` (sama dengan `padi_masuk.jumlah_transaksi`), dan `stok` (masih `0`).
Transaksi `void` tidak dihitung.
