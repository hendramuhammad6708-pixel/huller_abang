# AGENTS.md

## Layout

- Root has no manifests/scripts; apps `backend/` (Laravel 13 API) and `frontend/` (Flutter). API contracts in `docs/api/*.md` (auth/operator/pelanggan/pengaturan/padi-masuk); update them when payload/validation changes.
- Root `README.md` paths (`backend/src/...`) are stale — standard Laravel layout under `backend/`.
- Backend modules: auth, dashboard summary, operator, pelanggan, pengaturan/kelas-padi, padi masuk + penjemuran. Frontend `Penggilingan` is placeholder; dashboard summary currently returns `transaksi: 0`, `stok: 0`.

## Backend (`backend/`, Laravel 13)

Run from `backend/`. PHP ^8.3 (composer allows ^8.3); Laravel ^13.17.

- Setup: `composer setup` (install, copy `.env.example`→`.env`, key, migrate, build Vite). Needs MySQL DB `huller_abang`; no seeders by default.
- Seed: set `OWNER_PASSWORD` (optional `OWNER_USERNAME`) in `.env`, `php artisan db:seed` (seeds owner + default `kelas_padi`/`pengaturan`). `OwnerSeeder` warns/skips if password empty.
- Dev: `composer dev` (`php artisan dev`). For Android emulator expose `php artisan serve --host=0.0.0.0 --port=8000`. Vite `npm run dev`/`npm run build`.
- Tests: `composer test` (clears config, runs `artisan test`); focused `php artisan test --filter=...` or `php artisan test tests/Feature/FooTest.php`. Feature tests use `RefreshDatabase` against MySQL `huller_abang_test` (phpunit.xml sets `DB_CONNECTION=mysql`, `DB_DATABASE=huller_abang_test`; creds from `.env`) — create DB or tests fail. Don't switch to sqlite without agreement.
- Style: `vendor/bin/pint` (`vendor/bin/pint --test`).

### API conventions
- Responses via `App\Support\ApiResponse::sukses($message, $data=null, $status=200)` / `::gagal($message, $status, $errors=[])` → `{success,message,data,errors?}`. No hand-rolled JSON.
- JSON errors (422 as `errors: [{field,message}]`, 401/404/405) registered in `bootstrap/app.php` via `App\Support\ApiExceptions::daftarkan()` and apply only to `api/*` (web routes unchanged).
- Add routes at bottom comment in `backend/routes/api.php`. Health: `GET /api/health` (DB check), framework `/up`.
- Pagination: `page`/`limit` (max 100) → `data.items` + `data.meta.total`. Exception: `GET /api/kelas-padi` returns all items with `meta.total` only.
- Roles: middleware alias `role` (`App\Http\Middleware\CheckRole`), returns 403 via `ApiResponse::gagal` — no ad-hoc checks.
- Padi masuk/penjemuran open to `owner`/`operator` (auth:sanctum). Routes grouped in `api.php`; update `docs/api/padi-masuk.md` on changes.

### Padi masuk / penjemuran (rules)
- Validation in FormRequests: `PadiMasukRequest` (tanggal Y-m-d, pelanggan_id exists non-deleted, kelas_padi_id exists, berat_basah_kg numeric>0 max 2 decimals <=99999999.99, catatan trimmed nullable max 1000). `RiwayatPadiMasukRequest` filters (`search`, `pelanggan_id`, `kelas_padi_id`, `status` in `PadiMasuk::STATUS`, `tanggal_dari/sampai` with `after_or_equal`, pagination). History exposed via `PadiMasukController@index`/`log`.
- State/calcs in `App\Services\PadiMasukService`: status `MASUK`→`DIJEMUR`→`SIAP_GILING`. Start drying sets `penjemuran.tanggal_mulai` (defaults today), updates status to `DIJEMUR`. Finish drying requires existing `penjemuran`, computes `durasi_hari = floor(diff in days mulai->selesai)` (>=0), `persen_susut = round((berat_basah - berat_kering)/berat_basah*100,2)`, sets `penjemuran` fields + status `SIAP_GILING`. If `durasi_hari < PadiMasuk::AMBANG_DURASI_HARI` (warning <2 hari) adds warning message in log keterangan. `berat_kering_kg` must be <= `berat_basah_kg` enforced by controller/service flow (no explicit global rule shown except service logic).
- Audit: every create/update/start/finish writes `log_padi_masuk` via `tulisLog` with `user_id`, `nama_pengguna`, `aksi`, `perubahan[]` (`{field,sebelum,sesudah}`), `keterangan`. `PadiMasukController@log` returns logs.

### Schema / auth
- `users`: no email, login by unique `username` (`nama`, `username`, `password`, `role` enum `owner`|`operator`, `aktif`). `User` casts `password` hashed; `OperatorController` also does `Hash::make` (only once). Inactive users auth with correct password → 403; deleting operator revokes tokens.
- Auth Sanctum bearer tokens (`HasApiTokens`), no session auth.
- Tables Indonesian/unprefixed: `users`, `pelanggan` (soft deletes), `pengaturan` (key/value), `kelas_padi`, `padi_masuk`, `penjemuran`, `log_padi_masuk`.

## Frontend (`frontend/`, Flutter)

Run all commands from `frontend/`.

- Commands: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`. The only test file is `frontend/test/widget_test.dart`; focused: `flutter test test/widget_test.dart --plain-name "nama test"`. Tests cover login widgets, pelanggan model/validator, settings parsers, and local bagi-hasil math — no HTTP is mocked.
- API base URL is a compile-time define in `lib/core/api_client.dart`: `--dart-define=API_URL=http://<host>:8000/api`. Default is `http://10.0.2.2:8000/api` (Android emulator → host). On Windows/web use `http://localhost:8000/api`; a physical device needs the computer's LAN IP. The backend must listen on `0.0.0.0` for emulator/device access. Android cleartext HTTP is enabled.
- Auth lives in `lib/core/sesi.dart`: singleton `Sesi.instance`, token persisted in `SharedPreferences` under key `token`, restored by calling `GET /me` at startup. Role guard is `Sesi.instance.owner`; `lib/home_shell.dart` builds tabs by role (owner: Dashboard/Pelanggan/Operator/Pengaturan/Penggilingan; operator: only Penggilingan).
- Data is loaded from the real API. Pelanggan and Operator both fetch with `limit=100`; Pelanggan search/type filtering is client-side. Penggilingan is still a placeholder, so the padi masuk/penjemuran API has no Flutter consumer yet.

## Conventions

- Indonesian everywhere: identifiers, table/column names, API messages, code comments, and commit messages.
- Commit messages mix `feat:`/`fix:`/`chore:` prefixes with plain Indonesian sentences; either is acceptable.
