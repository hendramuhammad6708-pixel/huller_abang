# API Pengaturan & Kelas Padi

Dasar alamat: `http://localhost:8000/api`
Kirim header `Accept: application/json` (dan `Content-Type: application/json` untuk PUT/POST).

**Hak akses:** Owner, kecuali `GET /api/pengaturan`, `GET /api/kelas-padi`, dan `POST /api/bagi-hasil` yang juga boleh diakses operator (baca/hitung saja, dipakai pada form padi masuk). Semua endpoint modul ini butuh header `Authorization: Bearer <token>` (login dulu lewat `POST /api/login`).
Tanpa token → `401`; token role operator → `403` untuk endpoint ubah/tambah/hapus.

Format respons sama dengan dokumen `pelanggan.md`.

---

## GET /api/pengaturan — ambil persentase

Respons `200`:
```json
{
  "success": true,
  "message": "Pengaturan sistem",
  "data": { "persen_upah": 5, "persen_hak_operator": 5 }
}
```
- `persen_upah`: persentase upah huller dari beras bersih.
- `persen_hak_operator`: persentase hak operator dari upah kotor.

## PUT /api/pengaturan — ubah persentase

Boleh mengirim salah satu atau keduanya (minimal satu). Nilai berupa angka 0–100 (boleh desimal).

Body:
```json
{ "persen_upah": 5, "persen_hak_operator": 2.5 }
```
Respons `200`: `data` berisi nilai terbaru (sama seperti GET).
Sebelum nilai baru disimpan, server mencatat baris di tabel `log_pengaturan` berisi `user_id`, `upah_lama`, `upah_baru`, `hak_operator_lama`, `hak_operator_baru`, dan `created_at`. Jika salah satu persen tidak dikirim, nilai lama dipakai sebagai nilai baru pada kolom terkait.
Respons `422` jika nilai bukan angka, kurang dari 0, lebih dari 100, atau tidak ada yang dikirim.

---

## GET /api/kelas-padi — daftar kelas padi

Respons `200` (master kecil: seluruh data dikirim sekaligus):
```json
{
  "success": true,
  "message": "Daftar kelas padi",
  "data": {
    "items": [ { "id": 1, "nama_kelas": "Kelas 1" }, { "id": 2, "nama_kelas": "Kelas 2" } ],
    "meta": { "total": 2 }
  }
}
```

## POST /api/kelas-padi — tambah kelas

Body: `{ "nama_kelas": "Kelas 3" }` (wajib, maksimal 50 karakter, tidak boleh sama dengan yang sudah ada).
Respons `201`: `data` berisi `id`. Respons `422` jika kosong atau nama sudah ada.

## PUT /api/kelas-padi/{id} — ubah nama kelas

Body: `{ "nama_kelas": "Kelas Super" }`
Respons `200`: `data` berisi `id`. Respons `404` jika id tidak ada, `422` jika tidak valid atau nama dobel.

## DELETE /api/kelas-padi/{id} — hapus kelas

Respons `200` jika berhasil. Respons `404` jika id tidak ada.
Respons `409` jika kelas sudah dipakai data padi masuk.

## POST /api/bagi-hasil — hitung pembagian upah

Endpoint ini tersedia untuk owner dan operator (cukup token Sanctum, tanpa middleware `role:owner`). Semua angka dibulatkan 2 desimal oleh backend.

Body:
```json
{ "berat_bersih_kg": 1000, "persen_upah": 5, "persen_hak_operator": 5 }
```
Aturan: `berat_bersih_kg` > 0, maksimal 2 desimal, maksimal `99999999.99`; kedua persen 0–100, maksimal 2 desimal.

Respons `200`:
```json
{
  "success": true,
  "message": "Hasil bagi hasil",
  "data": {
    "beras_bersih_kg": 1000,
    "persen_upah": 5,
    "persen_hak_operator": 5,
    "upah_kg": 50,
    "operator_kg": 2.5,
    "huller_kg": 47.5,
    "saldo_pelanggan_kg": 950
  }
}
```
`upah_kg` = beras bersih × persen upah; `operator_kg` = upah × persen hak operator; `huller_kg` = upah − operator; `saldo_pelanggan_kg` = beras bersih − upah. Respons `422` jika isian tidak valid.

## Ringkasan kode status

| Kode | Arti |
|---|---|
| 200 | Berhasil |
| 201 | Berhasil dibuat |
| 401 | Token tidak diberikan / sesi berakhir |
| 403 | Role bukan owner |
| 404 | Data tidak ditemukan |
| 409 | Konflik (kelas sedang dipakai) |
| 422 | Isian tidak valid |