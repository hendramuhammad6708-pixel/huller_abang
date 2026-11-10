# AGENTS.md

## Layout

- Root has no manifests/scripts; apps `backend/` (Laravel 13, API-only) and `frontend/` (Flutter). API contracts in `docs/api/*.md` (operator, pelanggan, pengaturan); update them when payload/validation changes.
- Root `README.md` paths (`backend/src/...`) are stale — standard Laravel layout under `backend/`.
- CI (`.github/workflows/`): `backend-laravel.yml` runs only on push/PR to `develop` (PHP 8.4 + MySQL 8.0 service; `vendor/bin/pint --test` then `php artisan test`). `frontend-flutter.yml` triggers on `feature/fe-flutter`, a branch that no longer exists on origin — frontend CI effectively never runs.

## Backend (`backend/`, Laravel 13)

Run from `backend/`. `composer.json`/`composer.lock` require PHP ^8.3; CI pins PHP 8.4.

- Setup: `composer setup` (install, copy `.env.example`→`.env`, key, migrate, npm build). Needs MySQL DB `huller_abang`.
- Seed: set `OWNER_PASSWORD` (optional `OWNER_USERNAME`) in `.env`, then `php artisan db:seed` (owner + default `kelas_padi`/`pengaturan`). `OwnerSeeder` warns and skips if password empty.
- Dev: `composer dev`. For Android emulator/device access serve on all interfaces: `php artisan serve --host=0.0.0.0 --port=8000`.
- Tests: `composer test` (clears config, runs `artisan test`); focused `php artisan test --filter=...` or `php artisan test tests/Feature/FooTest.php`. Feature tests use `RefreshDatabase` against MySQL `huller_abang_test` (phpunit.xml sets `DB_CONNECTION=mysql`, `DB_DATABASE=huller_abang_test`; creds from `.env`) — create the DB or tests fail. Don't switch to sqlite without agreement.
- Style: `vendor/bin/pint` (`vendor/bin/pint --test`).

### Padi masuk / penjemuran backend is NOT in the repo

- `routes/api.php` registers `/api/padi-masuk` and `/api/penjemuran` routes pointing to `PadiMasukController` / `PenjemuranController`, but those classes, their FormRequests/Service/Models, and the `padi_masuk`/`penjemuran`/`log_padi_masuk` migrations were never committed to any branch (`git log --all` confirms). Requests to these routes fail with "class does not exist". The Flutter padi masuk and penjemuran features are complete and call these endpoints — don't assume the backend exists; verify or ask before working on this module.

### API conventions

- Responses via `App\Support\ApiResponse::sukses($message, $data=null, $status=200)` / `::gagal($message, $status, $errors=[])` → `{success,message,data,errors?}`. No hand-rolled JSON.
- JSON errors (422 as `errors: [{field,message}]`, 401/404/405) registered in `bootstrap/app.php` via `App\Support\ApiExceptions::daftarkan()` and apply only to `api/*`; guests are not redirected (`redirectGuestsTo(null)`) since there is no web login.
- Add routes at the bottom comment in `backend/routes/api.php` ("Daftar route modul"). Health: `GET /api/health` (DB check), framework `/up`.
- Pagination: `page`/`limit` (default 10, max 100) → `data.items` + `data.meta.total`. Exception: `GET /api/kelas-padi` returns all items with `meta.total` only.
- Roles: middleware alias `role` (`App\Http\Middleware\CheckRole`), returns 403 via `ApiResponse::gagal` — no ad-hoc checks.
- Implemented modules: auth, dashboard summary, operator, pelanggan, pengaturan/kelas-padi. Dashboard summary returns real counts but `transaksi`/`stok` are hardcoded `0`.

### Schema / auth

- `users`: no email, login by unique `username` (`nama`, `username`, `password`, `role` enum `owner`|`operator`, `aktif`). `User` casts `password` hashed; `OperatorController` also does `Hash::make` (the `hashed` cast detects it — hashed only once). Inactive user with correct password → 403; deleting an operator revokes tokens.
- Auth Sanctum bearer tokens (`HasApiTokens`), no session auth.
- Tables Indonesian/unprefixed: `users`, `pelanggan` (soft deletes), `pengaturan` (`kunci`/`nilai`/`keterangan`), `kelas_padi`, `personal_access_tokens`.

## Frontend (`frontend/`, Flutter)

Run all commands from `frontend/`.

- Commands: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`. Focused: `flutter test test/widget_test.dart --plain-name "nama test"`. Tests: `widget_test.dart` (login widgets, pelanggan model/validator, pengaturan persen parser, local bagi-hasil math), `padi_masuk_test.dart` (validator/model/controller query string), `tampilan_test.dart` (renders each page at 360px — layout overflow fails the test; API calls fail in tests so error states are covered; `PenjemuranService` is faked via subclass).
- API base URL is a compile-time define in `lib/core/api_client.dart` (also used by `PenjemuranService`): `--dart-define=API_URL=http://<host>:8000/api`. Default is `http://10.0.2.2:8000/api` (Android emulator → host). On Windows/web use `http://localhost:8000/api`; a physical device needs the computer's LAN IP. The backend must listen on `0.0.0.0`. Android cleartext HTTP is enabled.
- Auth lives in `lib/core/sesi.dart`: singleton `Sesi.instance`, token persisted in `SharedPreferences` under key `token`, restored by calling `GET /me` at startup. Role guard is `Sesi.instance.owner`.
- `lib/home_shell.dart` builds tabs by role — owner: Dashboard, Padi Masuk, Penjemuran, Pelanggan, Lainnya (Operator + Pengaturan live inside Lainnya); operator: Padi Masuk and Penjemuran only.
- Padi masuk (`features/penggilingan`) and penjemuran (`features/penjemuran`) fetch from the real API with `limit=100` and server-side filters (`dari`/`sampai`/`pelanggan_id`/`kelas_padi_id`, plus `status`/`tanggal_dari`/`tanggal_sampai` for penjemuran) — but these backend endpoints don't exist yet (see backend section).

## Conventions

- Indonesian everywhere: identifiers, table/column names, API messages, code comments, and commit messages.
- Commit messages mix `feat:`/`fix:`/`chore:` prefixes with plain Indonesian sentences; either is acceptable.
