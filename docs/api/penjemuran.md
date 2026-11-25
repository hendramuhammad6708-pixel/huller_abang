# API Penjemuran

Dasar alamat: `http://localhost:8000/api`
**Hak akses:** owner dan operator. Tanpa token → `401`.
Id pada alamat adalah **id padi masuk** (satu padi masuk punya satu catatan penjemuran).

## Status otomatis
`masuk` → (mulai jemur) `dijemur` → (selesai jemur) `siap_giling`.
Urutan yang salah dijawab `409`.

## Bentuk satu baris
```json
{ "id": 12, "nomor_transaksi": "PM-20261026-0012", "pelanggan": "Pak Budi", "kelas": "Premium",
  "tanggal_masuk": "2026-10-26", "berat_basah": 200,
  "tanggal_mulai": "2026-10-27", "tanggal_selesai": null, "berat_kering": null,
  "persen_susut": null, "durasi_hari": 5, "terlalu_lama": true,
  "boleh_diselesaikan": true, "tanggal_paling_cepat_selesai": "2026-10-29",
  "status": "dijemur", "status_label": "Dijemur" }
```

**Durasi jemur dihitung server** (hari kalender, zona waktu WIB): selama `dijemur` dihitung sampai hari ini, setelah selesai sampai `tanggal_selesai`; `null` bila belum dimulai.
`terlalu_lama` bernilai `true` bila masih `dijemur` lebih dari 3 hari.
`persen_susut = (berat_basah - berat_kering) / berat_basah × 100`, dibulatkan 2 desimal, terisi setelah penjemuran selesai.

## GET /api/penjemuran
Query (opsional): `status` (`masuk`, `dijemur`, `siap_giling`), `pelanggan_id`, `tanggal_dari`, `tanggal_sampai` (tanggal masuk).
Hanya padi berstatus `masuk`, `dijemur`, dan `siap_giling` yang tampil (tanpa `void` dan `selesai_giling`).

**Catatan:** `data` berupa **daftar biasa**, bukan `items`/`meta`, karena itu yang dibaca aplikasi Flutter dan jumlahnya kecil (hanya padi yang belum selesai giling).

## POST /api/penjemuran/{id}/mulai   (juga: POST /api/padi-masuk/{id}/penjemuran)
Body `{ "tanggal_mulai": "2026-10-27" }`. Wajib, tidak boleh sebelum tanggal padi masuk atau di masa depan.
Hanya dari status `masuk` (selain itu `409`). Respons `200` (`201` untuk alamat `/padi-masuk/{id}/penjemuran`) berisi baris penjemuran.

## POST /api/penjemuran/{id}/selesai
Body `{ "tanggal_selesai": "2026-10-30", "berat_kering": 170 }`.
| Field | Aturan |
|---|---|
| `tanggal_selesai` | wajib, **paling cepat 2 hari setelah tanggal mulai** dan tidak boleh di masa depan |
| `berat_kering` | wajib, lebih dari 0 dan tidak boleh melebihi berat basah |

**Penjemuran minimal 2 hari.** Mulai tanggal 27 berarti paling cepat bisa diselesaikan tanggal 29. Bila kurang, respons `422` pada field `tanggal_selesai`:
`"Penjemuran minimal 2 hari. Paling cepat bisa diselesaikan pada 2026-10-29."` Tidak ada yang berubah di data.
Karena itu baris penjemuran membawa `boleh_diselesaikan` (`true` bila status `dijemur` dan sudah 2 hari) dan `tanggal_paling_cepat_selesai` (mulai + 2 hari, `null` bila belum dimulai); aplikasi memakainya untuk menonaktifkan tombol "Selesaikan".

Hanya dari status `dijemur` (selain itu `409`). Status menjadi `siap_giling`.

## PUT /api/padi-masuk/{id}/penjemuran — koreksi data
Body (semua opsional): `tanggal_mulai`, `tanggal_selesai`, `berat_kering`. `tanggal_selesai` dan `berat_kering` hanya berlaku saat `siap_giling`.
`409` bila padi belum punya data penjemuran, atau bila koreksi membuat penjemuran yang sudah selesai menjadi kurang dari 2 hari.

Setiap perubahan tercatat di log padi masuk (lihat [padi-masuk.md](padi-masuk.md)).
