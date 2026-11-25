# API Bagi Hasil

Dasar alamat: `http://localhost:8000/api`
**Hak akses:** owner dan operator. Tanpa token → `401`.

## POST /api/bagi-hasil
Menghitung bagi hasil satu kali penggilingan. Tidak menyimpan apa pun.

Body:
```json
{ "berat_bersih_kg": 1000, "persen_upah": 5, "persen_hak_operator": 5 }
```
| Field | Aturan |
|---|---|
| `berat_bersih_kg` | wajib, angka lebih dari 0 (berat beras bersih) |
| `persen_upah` | opsional, 0–100; bila tidak dikirim memakai pengaturan |
| `persen_hak_operator` | opsional, 0–100; bila tidak dikirim memakai pengaturan |

Rumus (tiap langkah dibulatkan 2 desimal):
```
upah            = berat_bersih × persen_upah / 100
hak operator    = upah × persen_hak_operator / 100
hak huller      = upah − hak operator
saldo pelanggan = berat_bersih − upah
```

Respons `200`:
```json
{ "success": true, "message": "Hasil bagi hasil",
  "data": { "berat_bersih_kg": 1000, "persen_upah": 5, "persen_hak_operator": 5,
            "upah_kg": 50, "operator_kg": 2.5, "huller_kg": 47.5, "saldo_pelanggan_kg": 950 } }
```
`422` bila isian tidak valid. Persentase bawaan diubah owner lewat `PUT /api/pengaturan` (lihat [pengaturan.md](pengaturan.md)).
