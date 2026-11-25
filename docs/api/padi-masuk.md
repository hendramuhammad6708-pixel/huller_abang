# API Padi Masuk

Dasar alamat: `http://localhost:8000/api`
**Hak akses:** owner dan operator (cukup token yang valid dan akun aktif). Tanpa token → `401`.

## Alur status
`masuk` → `dijemur` → `siap_giling` → `selesai_giling`. `void` bisa dari status mana pun kecuali `selesai_giling`.
Pelanggaran urutan dijawab `409` dengan pesan yang menjelaskan alasannya.

## Bentuk satu transaksi
```json
{
  "id": 12, "nomor_transaksi": "PM-20261026-0012", "tanggal": "2026-10-26",
  "pelanggan_id": 1, "nama_pelanggan": "Pak Budi",
  "pelanggan": { "id": 1, "nama": "Pak Budi", "kontak": "0812…", "tipe_pelanggan": "petani" },
  "kelas_padi_id": 2, "nama_kelas": "Premium", "kelas_padi": { "id": 2, "nama_kelas": "Premium" },
  "berat_basah_kg": 250.5, "catatan": null,
  "status": "dijemur", "status_label": "Dijemur",
  "berat_kering_kg": null, "persen_susut": null, "tanggal_selesai_giling": null,
  "void_reason": null, "void_by": null,
  "penjemuran": { "tanggal_mulai": "2026-10-27", "tanggal_selesai": null, "berat_kering_kg": null, "durasi_hari": 2 },
  "created_at": "2026-10-26T02:15:00.000000Z"
}
```
`nomor_transaksi` dibuat otomatis (`PM-` + tanggal + id 4 digit). `penjemuran` bernilai `null` sebelum penjemuran dimulai.

## GET /api/padi-masuk
Query (opsional): `dari`, `sampai` (`YYYY-MM-DD`, sampai tidak boleh sebelum dari), `pelanggan_id`, `kelas_padi_id`, `status`, `page` (default 1), `limit` (default 10, maksimal 100 — lebih dari itu `422`).
Urutan: tanggal terbaru, lalu id terbesar. Transaksi `void` ikut tampil.

```json
{ "data": { "items": [ { "...": "bentuk transaksi" } ],
            "meta": { "page": 1, "limit": 100, "total": 250,
                      "jumlah_aktif": 240, "total_berat_kg": 48000.5 } } }
```
`jumlah_aktif` dan `total_berat_kg` mencakup **seluruh** hasil filter (bukan hanya halaman ini) dan tidak menghitung `void`.

## POST /api/padi-masuk — catat padi masuk
```json
{ "tanggal": "2026-10-26", "pelanggan_id": 1, "kelas_padi_id": 2, "berat_basah_kg": 250.5, "catatan": "Agak basah" }
```
| Field | Aturan |
|---|---|
| `tanggal` | wajib, `YYYY-MM-DD`, tidak boleh lebih dari hari ini (zona waktu WIB) |
| `pelanggan_id` | wajib, pelanggan yang ada dan belum dihapus |
| `kelas_padi_id` | wajib, kelas padi yang ada |
| `berat_basah_kg` | wajib, angka lebih dari 0 |
| `catatan` | boleh kosong, maksimal 255 karakter |

Respons `201` berisi transaksi. `422` bila tidak valid.

## GET /api/padi-masuk/{id}
Respons `200` berisi transaksi, `404` bila tidak ada.

## PUT /api/padi-masuk/{id}
Kirim seluruh field seperti POST. Hanya selama status `masuk`, selain itu `409`.

## POST /api/padi-masuk/{id}/void — batalkan
Body `{ "alasan": "Salah input berat" }` (wajib, 3–255 karakter). Data tidak dihapus, hanya ditandai `void` beserta `void_reason` dan `void_by`.
`409` bila sudah `void` atau sudah `selesai_giling`. Tidak ada `DELETE`.

## POST /api/padi-masuk/{id}/selesai-giling
Body opsional `{ "tanggal_selesai_giling": "2026-10-30" }` (default hari ini; tidak boleh sebelum tanggal padi masuk atau di masa depan).
Hanya dari status `siap_giling`, selain itu `409`.

## GET /api/padi-masuk/{id}/log
Jejak audit, terbaru dulu, berpaginasi (`page`, `limit`). Aksi: `dibuat`, `diubah`, `void`, `mulai_jemur`, `selesai_jemur`, `ubah_jemur`, `selesai_giling`.
```json
{ "data": { "items": [ { "id": 5, "aksi": "void", "keterangan": "Salah input",
                         "user": { "id": 3, "nama": "Operator Satu" }, "created_at": "…" } ],
            "meta": { "page": 1, "limit": 20, "total": 3 } } }
```

Penjemuran padi ini dibahas di [penjemuran.md](penjemuran.md).
