# AGENTS.md

## Branch layout (read this first)

- `main` is intentionally empty (README + `.gitkeep` only). The Laravel backend was reverted on purpose via PR #3 (`revert-2-chore/be-setup-laravel`). Do **not** recreate backend scaffolding on `main`.
- Real code lives on branches; check it out before working (no root manifest exists, only files inside `backend/` or `frontend/`):
  - `origin/develop` — Laravel backend in `backend/`
  - `origin/features` — static frontend login prototype in `frontend/src/`
- Start PRs from / into the branch you worked on (`develop`, `features`, topic branches like `halaman-daftar-pelanggan`), not into `main`.
- CI exists via GitHub Actions (no pre-commit hooks, no root lint/typecheck scripts): `backend-laravel.yml` runs Pint + tests on `develop`; `frontend-flutter.yml` runs `flutter analyze` + `flutter test` on `feature/fe-flutter`. Verify locally the same way before pushing.

## Backend (`origin/develop`, Laravel 13 / PHP 8.4+)

Run all commands from `backend/`.

- One-time setup: `composer setup` — `composer install`, copies `.env.example` → `.env`, `key:generate`, `migrate --force`, `npm install`, `npm run build`.
  - Needs a local MySQL DB named `huller_abang` (see `backend/.env.example`); frontend dev URL is `FRONTEND_URL=http://localhost:5173`.
- Dev server: `composer dev` (= `php artisan dev`). Vite assets: `npm run dev` / `npm run build`.
- Tests: `composer test` (runs `config:clear` then `artisan test`); focused: `php artisan test --filter=...` or `php artisan test tests/Feature/FooTest.php`.
  - Tests hit a **MySQL** database `huller_abang_test` per `phpunit.xml` (`DB_CONNECTION=mysql`) and use `RefreshDatabase` — create that empty DB first or every Feature test fails. Do not switch back to sqlite `:memory:` without team agreement.
- Style: Laravel Pint is a dev dependency (`vendor/bin/pint`), default config (no `pint.json`).

### API conventions (must follow)

- Every response goes through `App\Support\ApiResponse::sukses()` / `::gagal()` → `{success, message, data, errors?}`. Do not hand-roll error JSON. Note `sukses()` takes `(message, data, status)`, `gagal()` takes `(message, status, errors)`.
- JSON error rendering (422 validation as `errors: [{field, message}]`, 404, 405) is registered globally in `bootstrap/app.php` via `App\Support\ApiExceptions::daftarkan()`; it only applies to `api/*`. Web routes (`routes/web.php`) never return this shape.
- New API modules add their route lines at the marked spot at the bottom of `backend/routes/api.php`. Health check: `GET /api/health`.
- List endpoints must paginate (`page`/`limit`) and return `data.items` + `data.meta.total` (Sprint convention in root `README.md`).
- Role guard is the middleware alias `role` (e.g. `role:owner`), implemented by `App\Http\Middleware\CheckRole` — it returns 403 via `ApiResponse::gagal`. Add new role-restricted routes with this alias, not ad-hoc checks.

### Schema facts that differ from Laravel defaults

- `users` has **no email**: login is by unique `username`; columns are `nama`, `password`, `role` enum (`owner`|`operator`), `aktif` boolean.
- Auth is Sanctum tokens (`HasApiTokens`), no session auth for the API.
- Tables are Indonesian and unprefixed: `users`, `pelanggan` (soft deletes), `pengaturan` (key/value), `kelas_padi`. Keep new tables in that naming style.
- `OwnerSeeder` reads `OWNER_USERNAME` / `OWNER_PASSWORD` from `.env` and **skips creating the owner with a warning if the password is empty**.

## Frontend (`origin/features`)

- Plain static HTML/CSS/JS — no `package.json`, no build step; open the pages directly or via any static server.
- `frontend/src/services/authApi.js` is a deliberate mock ("server palsu") with hardcoded accounts; it must be replaced with real `fetch()` calls to the backend API.
- Session/guards live in `frontend/src/router/guard.js`: key `huller_session`, stored in `localStorage` when "remember" is set, else `sessionStorage`; use `requireLogin(role)` / `redirectIfLoggedIn()`.

## Conventions

- Indonesian everywhere: identifiers, table/column names, API messages, code comments, and commit messages (e.g. "tambah migrasi users, pelanggan"). Keep new user-facing strings and commits in Indonesian.
- Commit messages mix `feat:`/`fix:`/`chore:` prefixes with plain Indonesian sentences; either is acceptable.
