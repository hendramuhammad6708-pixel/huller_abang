# API Manajemen Akun Operator

Dasar alamat: `http://localhost:8000/api`
Kirim header `Accept: application/json` (dan `Content-Type: application/json` untuk POST/PUT).

**Hak akses:** Owner. Semua endpoint modul ini butuh header `Authorization: Bearer <token>` (login dulu lewat `POST /api/login`).
Tanpa token → `401`; token role operator → `403`.

Format respons sama dengan dokumen `pelanggan.md`.

## Aturan isian

| Field | Aturan |
|---|---|
| `nama` | wajib saat tambah; teks, maksimal 100 karakter |
| `username` | wajib saat tambah; maksimal 50 karakter, unik, dipakai untuk login |
| `password` | wajib saat tambah; minimal 6 karakter, disimpan ter-hash |
| `aktif` | boolean; default `true`. Operator nonaktif tidak bisa login |

---

## GET /api/operators — daftar operator

Query (semua opsional): `search` (cari nama/username), `aktif` (`1`/`true` atau `0`/`false`), `page` (default 1), `limit` (default 10, maksimal 100).

Contoh: `GET /api/operators?search=budi&aktif=1&page=1&limit=10`

Respons `200`:
```json
{
  "success": true,
  "message": "Daftar operator",
  "data": {
    "items": [
      { "id": 3, "nama": "Pak Budi", "username": "budi", "aktif": true,
        "created_at": "2026-10-20T09:30:36.000000Z" }
    ],
    "meta": { "page": 1, "limit": 10, "total": 1 }
  }
}
```
Hanya akun ber-`role` operator; akun owner tidak ikut tampil. Field `password` tidak pernah dikirim.

## GET /api/operators/{id} — detail

Respons `200`: `data.operator` berisi `id, nama, username, aktif, created_at, updated_at`.
Respons `404` jika id tidak ada atau bukan operator.

## POST /api/operators — tambah operator

Body:
```json
{ "nama": "Operator Baru", "username": "operator2", "password": "rahasia456", "aktif": true }
```
Respons `201`: `data.operator` berisi data operator baru.
Respons `422` jika isian tidak valid atau `username` sudah dipakai.

## PUT /api/operators/{id} — ubah operator (termasuk reset password)

Semua field bersifat opsional; kirim hanya yang ingin diubah.
- Ubah data: `{ "nama": "Nama Baru", "username": "user_baru" }`
- Reset password: `{ "password": "sandi_baru1" }` (minimal 6 karakter, otomatis di-hash)
- Aktif/nonaktif: `{ "aktif": false }`

Respons `200`: `data.operator` berisi data terbaru.
Respons `404` jika id tidak ada atau bukan operator; `422` jika tidak valid.

## DELETE /api/operators/{id} — hapus operator

Semua token milik operator ikut tercabut.
Respons `200`. Respons `404` jika id tidak ada atau bukan operator.

---

## Ringkasan kode status

| Kode | Arti |
|---|---|
| 200 | Berhasil |
| 201 | Berhasil dibuat |
| 401 | Token tidak diberikan / sesi berakhir |
| 403 | Role bukan owner |
| 404 | Data tidak ditemukan / bukan operator |
| 422 | Isian tidak valid / username sudah dipakai |
