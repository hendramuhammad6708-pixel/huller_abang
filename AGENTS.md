# AGENTS.md

## Layout

- Root has no manifests/scripts; work from `backend/` (Laravel 13 JSON API) or `frontend/` (Flutter). Root `README.md` paths under `backend/src/...` are stale.
- `docs/api/*.md` are partial: no auth/dashboard/health or flat `/api/penjemuran*` docs; nested penjemuran is in `padi-masuk.md`, `POST /api/bagi-hasil` in `pengaturan.md`. Update docs when payload/validation changes.
- Dashboard summary uses real padi-masuk/penjemuran counts; `stok` is hardcoded `0`.
- CI: backend push/PR `develop` runs from `backend/` with PHP 8.4 (Composer allows ^8.3), MySQL 8 `huller_abang_test` (root/password), `vendor/bin/pint --test` then `php artisan test`. Frontend push/PR `feature/fe-flutter` runs from `frontend/`: `flutter pub get` → `flutter analyze` → `flutter test`.

## Backend

- Setup: `composer setup` (install, copy `.env.example`→`.env`, key, migrate, `npm install --ignore-scripts`, `npm run build`) needs MySQL DB `huller_abang` and seeds nothing. Set `OWNER_PASSWORD` (optional `OWNER_USERNAME=owner`) in `.env` then `php artisan db:seed` for owner + default `kelas_padi`/`pengaturan`; owner is skipped when the password is empty.
- Dev: `composer dev` = `php artisan dev`. For Flutter/emulator use `php artisan serve --host=0.0.0.0 --port=8000`; Vite is `npm run dev`/`npm run build`.
- Verify: `vendor/bin/pint --test` then `php artisan test` (exact CI test command); local `composer test` adds `config:clear`. Focused: `php artisan test --filter=...` or `php artisan test tests/Feature/FooTest.php`. Feature tests require a running MySQL `huller_abang_test`; `phpunit.xml` fixes connection/db, host/user/password come from `.env` locally and CI env in workflows; no SQLite fallback. Unit tests need no DB.

### API conventions

- `ApiResponse::sukses()` always emits `{success,message,data}` (data may be null); `gagal()` omits `data` and adds `errors` only for 422. 422 errors are `{field,message}`; 401/404/405 renderers are registered in `bootstrap/app.php` via `ApiExceptions::daftarkan()` and gated to `api/*`.
- Routes: public `/health` (checks DB) and `/login`; auth-only `/me`, `/logout`, dashboard, `POST /bagi-hasil`, read-only pelanggan/pengaturan/kelas-padi, and padi-masuk/penjemuran; owner-only operators and all other pelanggan/pengaturan/kelas-padi routes, including `GET /pelanggan/{id}/riwayat-transaksi`. `role` middleware returns 403 via `ApiResponse::gagal`; padi/penjemuran are owner+operator. Framework health is `/up`.
- Pagination `page`/`limit` (max 100) → `data.items` + `data.meta`; exceptions: `/kelas-padi` returns all + `meta.total`, `/penjemuran` has a plain array in `data`, `/pengaturan`, `/me`, dashboard are single objects. Pelanggan/operator silently clamp `limit`; padi-masuk and riwayat-transaksi reject `limit>100` with 422.
- State guards return 409: edit padi only while `masuk`, penjemuran mulai needs `masuk`, selesai needs `dijemur`, selesai-giling needs `siap_giling`; void fails only when already `void`. There is no `DELETE /padi-masuk/{id}`; use `POST /padi-masuk/{id}/void` with trimmed `alasan` 3–500 chars.

### Padi masuk / penjemuran

- FormRequests: `PadiMasukRequest` (tanggal `Y-m-d`, pelanggan_id existing non-deleted, kelas_padi_id exists, berat_basah_kg numeric>0 ≤99999999.99 with ≤2 decimals, catatan trimmed nullable ≤1000); riwayat filters `search`/`pelanggan_id`/`kelas_padi_id`/`status`/`tanggal_dari`/`tanggal_sampai`; customer history uses the same minus pelanggan/kelas. `MulaiPenjemuranRequest.tanggal_mulai` is optional: if supplied it must be ≥ padi tanggal, otherwise the service uses today. `SelesaiPenjemuranRequest` requires `berat_kering_kg` ≤ `berat_basah_kg` and `tanggal_selesai` ≥ tanggal_mulai; `BagiHasilRequest` requires berat>0 and two 0–100 percentages with ≤2 decimals.
- State/calcs in `App\Services\PadiMasukService`: lowercase `masuk` → `dijemur` → `siap_giling` (constants on `PadiMasuk`); the DB column is `status_transaksi`, not `status`. `durasi_hari = max(0, diff)`; `persen_susut = round((berat_basah-berat_kering)/berat_basah*100, 2)`. Duration < `AMBANG_DURASI_HARI` (2) triggers a warning; `BATAS_DURASI_TERLALU_LAMA` is 3 and feeds `penjemuran.durasi_terlalu_lama`. Ongoing duration is computed up to today while DB `durasi_hari` stays NULL until finish. `selesaikanGiling` also sets `tanggal_selesai_giling`; `batalkan` sets `void_reason`/`void_by`. `nomor_transaksi` (`PM-YYYYMMDD-XXXX`) is generated on create via `PadiMasuk::creating`/`App\Support\NomorTransaksi`, is immutable on edit, and is exposed by `format()`.
- Two response families: nested `format()` shape under `/api/padi-masuk/...`; flat Flutter list under `/api/penjemuran/...` (`id,pelanggan,kelas,tanggal_masuk,berat_basah,tanggal_mulai/selesai,berat_kering,status`; no `persen_susut`/`peringatan`). Flat filters are unvalidated, always exclude void, and ignore invalid `status`.
- Audit `log_padi_masuk` via `tulisLog()` on create/update/start/finish/giling/void; no-op updates are not logged. Actions: `dibuat`, `diubah`, `penjemuran_dimulai`, `penjemuran_selesai`, `selesai_giling`, `void`. `GET /padi-masuk/{id}/log` is paginated newest-first.

### Schema / auth

- `users` have no email; login uses unique `username`, with `role` enum `owner|operator` and `aktif`. `aktif` is checked only at login, so existing Sanctum tokens survive deactivation; deleting an operator revokes tokens, tokens have no configured expiry, and logout revokes only the current token. `User` casts password hashed; `OperatorController` also calls `Hash::make` (not double-hashed).
- Indonesian/unprefixed tables: `users`, `pelanggan` (soft deletes), `pengaturan`, `kelas_padi`, `padi_masuk`, `penjemuran`, `log_padi_masuk`, `log_pengaturan`. `PUT /pengaturan` logs old/new percentages before updating; each field is independently optional (`required_without`) and numeric 0–100.
- Bagi hasil: `upah = beras * persen_upah/100`, `operator = upah * persen_hak_operator/100`, `huller = upah - operator`, `saldo = beras - upah`; each step rounds to 2 decimals.
- `GET /pelanggan/{id}/riwayat-transaksi` returns `pelanggan`, `terakhir`, `items`, `meta`; `status_terakhir` comes from the latest non-void transaction regardless of filters.

## Frontend

- Verify: `flutter pub get`, `flutter analyze`, `flutter test`; focused `flutter test test/riwayat_transaksi_test.dart`. Tests: `widget_test.dart` (login, pelanggan model/validator, settings parsers, bagi-hasil math), `padi_masuk_test.dart`, `riwayat_transaksi_test.dart`, `tampilan_test.dart` (small-screen renders; no Penjemuran/HomeShell). No HTTP mocking; some tests intentionally rely on failed API calls for error/empty states.
- API base is compile-time `API_URL` in `lib/core/api_client.dart`: `--dart-define=API_URL=http://<host>:8000/api`, default `http://10.0.2.2:8000/api`; backend must bind `0.0.0.0`. Android `usesCleartextTraffic=true` is in the main manifest (all variants), but `INTERNET` permission exists only in debug/profile manifests, so release builds lack network permission.
- Auth/session: `Sesi.instance` singleton, token in SharedPreferences key `token`, restored via `GET /me`; login/logout call `/login`/`/logout`. `ApiClient` clears the token on 401 and flattens backend `errors` to field→message. `Sesi.instance.owner` only composes tabs in `lib/home_shell.dart` (owner 6 tabs; operator Padi Masuk + Penjemuran); it is not a route guard — backend roles enforce access. Phones show the first 3 owner tabs plus "Lainnya"; width ≥840 uses a NavigationRail.
- Data/pages: pelanggan, operator, and padi-masuk riwayat use `limit=100`; pelanggan search/type filtering is client-side. Padi masuk form/riwayat live in `features/penggilingan/`; the form loads read-only pelanggan/pengaturan/kelas-padi (operator-accessible). `PelangganCard` opens `features/pelanggan/pages/detail_pelanggan_page.dart` (edit/delete + history); history uses `RiwayatTransaksiController` and `/pelanggan/{id}/riwayat-transaksi?limit=100`, with `pelanggan.status_terakhir` driving summary text.
- Void uses `core/konfirmasi_void.dart` + `POST /padi-masuk/{id}/void` (never DELETE); void cards hide print/share actions. Bagi-hasil preview uses `POST /bagi-hasil` with local `BagiHasil.hitung` fallback; saving percentages uses `core/konfirmasi_pengaturan.dart`; padi cards print via `features/penggilingan/struk_padi_masuk.dart` (`pdf` + `printing`); share uses `core/share_pdf.dart` (Web Share API on web, `Printing.sharePdf` native sheet/download fallback).
- Contract quirks not to copy: frontend padi riwayat sends `dari`/`sampai` but backend expects `tanggal_dari`/`tanggal_sampai` (filters silently ignored); `PenjemuranService.selesai()` sends `berat_kering` but backend requires `berat_kering_kg` (422), and the service uses raw `http` with `ApiClient.dasar` after stripping `/api` (its `tokenGetter` is unused). Frontend validator drift: berat ≤1000000 and catatan ≤255 vs larger backend limits; the penjemuran page's `pelanggan_id` filter list is never populated.

## Conventions

- Indonesian identifiers, table/column names, API messages, comments, and commit subjects (optional `feat:`/`fix:`/`chore:`/`docs:`; plain Indonesian, milestone/revert/merge also occur). Keep English envelope keys, route names, and scaffold/generated comments; hand-written workflow/config labels may be Indonesian.
