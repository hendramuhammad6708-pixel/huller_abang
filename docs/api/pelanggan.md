# API Pelanggan

Dasar alamat: `http://localhost:8000/api`
Kirim header `Accept: application/json` (dan `Content-Type: application/json` untuk POST/PUT).

**Hak akses:** Owner, kecuali dua endpoint yang juga boleh dipakai operator: `GET /api/pelanggan` (daftar pada form padi masuk) dan `POST /api/pelanggan` (menambah pelanggan baru saat padi masuk, **hanya tipe `petani` dan `pengepul`**). Semua endpoint modul ini butuh header `Authorization: Bearer <token>` (login dulu lewat `POST /api/login`).
Tanpa token → `401`; token role operator → `403` untuk ubah, hapus, detail, dan riwayat transaksi.

## Format respons

Sukses:
```json
{ "success": true, "message": "…", "data": { } }
```
Gagal:
```json
{ "success": false, "message": "Data tidak valid",
  "errors": [ { "field": "nama", "message": "Nama wajib diisi" } ] }
```

## Aturan isian

| Field | Aturan |
|---|---|
| `nama` | wajib, teks, maksimal 100 karakter |
| `kontak` | boleh kosong; jika diisi hanya angka (boleh diawali `+`), 8–15 digit |
| `tipe_pelanggan` | wajib: `pengepul`, `petani`, atau `milik_huller` (operator hanya boleh `pengepul` atau `petani`) |

---

## GET /api/pelanggan — daftar pelanggan

Query (semua opsional): `search` (cari nama), `tipe` (filter tipe), `page` (default 1), `limit` (default 10, maksimal 100).

Contoh: `GET /api/pelanggan?search=bud&tipe=petani&page=1&limit=10`

Respons `200`:
```json
{
  "success": true,
  "message": "Daftar pelanggan",
  "data": {
    "items": [
      { "id": 1, "nama": "Pak Budi", "kontak": "081234567890",
        "tipe_pelanggan": "petani", "created_at": "2026-10-20T09:30:36.000000Z" }
    ],
    "meta": { "page": 1, "limit": 10, "total": 1 }
  }
}
```
Pelanggan yang sudah dihapus tidak ikut tampil.

## GET /api/pelanggan/{id} — detail

Respons `200`: `data` berisi `id, nama, kontak, tipe_pelanggan, created_at, updated_at`, dan `dibuat_oleh` (`{ id, nama, role }` pembuatnya, atau `null` untuk data lama) agar owner bisa meninjau pelanggan yang ditambah operator.
Respons `404` jika id tidak ada atau sudah dihapus.

## GET /api/pelanggan/{id}/riwayat-transaksi — riwayat transaksi pelanggan

Query (semua opsional): `search` (catatan atau nama kelas padi), `status` (`masuk`, `dijemur`, `siap_giling`, `selesai_giling`, `void`), `tanggal_dari`, `tanggal_sampai` (format `YYYY-MM-DD`, sampai tidak boleh sebelum dari), `page` (default 1), `limit` (default 10, maksimal 100).

Respons `200` (diurutkan dari tanggal terbaru, lalu id terbesar):
```json
{
  "success": true,
  "message": "Riwayat transaksi pelanggan",
  "data": {
    "pelanggan": { "id": 1, "nama": "Pak Budi", "kontak": "081234567890",
      "tipe_pelanggan": "petani", "status_terakhir": "dijemur",
      "status_terakhir_label": "Dijemur", "tanggal_terakhir": "2026-10-26" },
    "terakhir": { "id": 12, "status": "dijemur", "status_label": "Dijemur", "...": "..." },
    "items": [
      { "id": 12, "nomor_transaksi": "PM-20261026-0012", "tanggal": "2026-10-26",
        "pelanggan": { "id": 1, "nama": "Pak Budi", "terhapus": false },
        "kelas_padi": { "id": 2, "nama_kelas": "Premium" },
        "berat_basah_kg": 250.5, "berat_kering_kg": null, "persen_susut": null,
        "catatan": null, "status": "masuk", "status_label": "Masuk",
        "penjemuran": null }
    ],
    "meta": { "page": 1, "limit": 10, "total": 1 }
  }
}
```
Format tiap `items` dan `terakhir` sama dengan `GET /api/padi-masuk` (lihat `padi-masuk.md`); `terakhir` bernilai `null` jika pelanggan belum punya transaksi.

`status_terakhir`, `status_terakhir_label`, dan `tanggal_terakhir` diambil dari transaksi aktif terbaru (bukan `void`), diurutkan dari `tanggal` lalu `id` terbesar, dan tidak dipengaruhi filter `status`/tanggal. `tanggal_terakhir` memakai `tanggal_selesai_giling`, lalu `penjemuran.tanggal_mulai`, lalu `tanggal`. Flutter memakai status ini untuk memilih teks ringkasan: `dijemur` → "Sedang Dijemur X hari", `siap_giling` → "Siap Giling X hari", `selesai_giling` → "Giling X hari lalu"; `void` tidak dipakai sebagai status terakhir.

Respons `404` jika pelanggan tidak ada/sudah dihapus; `422` jika filter tidak valid (misal `limit=101`, tanggal salah format, atau `tanggal_sampai` sebelum `tanggal_dari`).

## POST /api/pelanggan — tambah

Body:
```json
{ "nama": "Pak Budi", "kontak": "081234567890", "tipe_pelanggan": "petani" }
```
Respons `201`:
```json
{ "success": true, "message": "Pelanggan berhasil ditambahkan", "data": { "id": 1 } }
```
Respons `422` jika isian tidak valid (lihat daftar `errors`), termasuk:
- operator mengirim `tipe_pelanggan: milik_huller`;
- duplikat: sudah ada pelanggan aktif dengan nama yang sama (huruf besar/kecil diabaikan) **dan** kontak yang sama (galat pada field `nama`). Nama yang sama tanpa kontak, atau dengan kontak berbeda, diizinkan.

Pembuat (owner atau operator) dicatat di kolom `dibuat_oleh`.

## PUT /api/pelanggan/{id} — ubah

Kirim seluruh field (`nama` dan `tipe_pelanggan` wajib; `kontak` yang tidak dikirim dikosongkan).
Respons `200`: `data` berisi `id`. Respons `404` jika tidak ada, `422` jika tidak valid.

## DELETE /api/pelanggan/{id} — hapus aman

Data tidak benar-benar dihapus dari database (hanya ditandai terhapus), sehingga riwayat padi masuk tetap utuh.
Respons `200`: `data` bernilai `null`. Respons `404` jika tidak ada atau sudah dihapus.

## Ringkasan kode status

| Kode | Arti |
|---|---|
| 200 | Berhasil |
| 201 | Berhasil dibuat |
| 401 | Token tidak diberikan / sesi berakhir |
| 403 | Role bukan owner |
| 404 | Data tidak ditemukan |
| 422 | Isian tidak valid |