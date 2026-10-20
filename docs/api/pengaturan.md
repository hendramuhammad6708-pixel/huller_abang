# API Pengaturan & Kelas Padi

Dasar alamat: `http://localhost:8000/api`
Kirim header `Accept: application/json` (dan `Content-Type: application/json` untuk PUT/POST).

**Hak akses:** Owner. Semua endpoint modul ini butuh header `Authorization: Bearer <token>` (login dulu lewat `POST /api/login`).
Tanpa token → `401`; token role operator → `403`.

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
Respons `409` jika kelas sudah dipakai data padi masuk (berlaku mulai Sprint 2, saat tabel padi masuk sudah ada).

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