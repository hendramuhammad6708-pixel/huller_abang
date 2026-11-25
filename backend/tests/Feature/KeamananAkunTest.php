<?php

namespace Tests\Feature;

use App\Models\KelasPadi;
use App\Models\Pelanggan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class KeamananAkunTest extends TestCase
{
    use RefreshDatabase;

    private function buat(string $role, string $username, bool $aktif = true): User
    {
        return User::create([
            'nama' => 'Pengguna '.$username,
            'username' => $username,
            'password' => 'rahasia123',
            'role' => $role,
            'aktif' => $aktif,
        ]);
    }

    private function bearer(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('auth')->plainTextToken];
    }

    // --- Hapus operator yang sudah punya transaksi (dulu HTTP 500 karena foreign key)

    public function test_hapus_operator_yang_sudah_mencatat_padi_berhasil_dan_riwayat_utuh(): void
    {
        $owner = $this->buat('owner', 'pemilik');
        $operator = $this->buat('operator', 'op1');
        $pelanggan = Pelanggan::create(['nama' => 'Pak Budi', 'tipe_pelanggan' => 'petani']);
        $kelas = KelasPadi::create(['nama_kelas' => 'Premium']);

        Sanctum::actingAs($operator);
        $id = $this->postJson('/api/padi-masuk', [
            'tanggal' => now()->toDateString(),
            'pelanggan_id' => $pelanggan->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 100,
        ])->assertCreated()->json('data.id');

        Sanctum::actingAs($owner);
        $this->deleteJson('/api/operators/'.$operator->id)->assertOk();

        $this->assertSoftDeleted('users', ['id' => $operator->id]);
        $this->assertDatabaseHas('padi_masuk', ['id' => $id, 'dibuat_oleh' => $operator->id]);
        $this->assertDatabaseHas('log_padi_masuk', ['padi_masuk_id' => $id, 'user_id' => $operator->id]);
        $this->getJson('/api/operators/'.$operator->id)->assertStatus(404);
    }

    public function test_operator_terhapus_tidak_bisa_login(): void
    {
        $operator = $this->buat('operator', 'op1');
        $operator->delete();

        $this->postJson('/api/login', ['username' => 'op1', 'password' => 'rahasia123'])
            ->assertStatus(401);
    }

    // --- Operator dinonaktifkan: sesi lama harus ikut mati

    public function test_menonaktifkan_operator_mencabut_token_lamanya(): void
    {
        $owner = $this->buat('owner', 'pemilik');
        $operator = $this->buat('operator', 'op1');
        $header = $this->bearer($operator);

        $this->withHeaders($header)->getJson('/api/padi-masuk')->assertOk();

        Sanctum::actingAs($owner);
        $this->putJson('/api/operators/'.$operator->id, ['aktif' => false])->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);

        // Panggil ulang sebagai klien baru supaya autentikasi Sanctum::actingAs tidak ikut terpakai
        $this->refreshApplication();
        $this->withHeaders($header)->getJson('/api/padi-masuk')->assertStatus(401);
    }

    public function test_mengganti_sandi_operator_mencabut_token_lamanya(): void
    {
        $owner = $this->buat('owner', 'pemilik');
        $operator = $this->buat('operator', 'op1');
        $operator->createToken('auth');

        Sanctum::actingAs($owner);
        $this->putJson('/api/operators/'.$operator->id, ['password' => 'sandibaru1'])->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_mengubah_nama_operator_tidak_mencabut_token(): void
    {
        $owner = $this->buat('owner', 'pemilik');
        $operator = $this->buat('operator', 'op1');
        $operator->createToken('auth');

        Sanctum::actingAs($owner);
        $this->putJson('/api/operators/'.$operator->id, ['nama' => 'Nama Baru'])->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 1);
    }

    public function test_akun_nonaktif_ditolak_walau_token_masih_ada(): void
    {
        // Status diubah langsung (bukan lewat OperatorController) sehingga token tidak dicabut
        $operator = $this->buat('operator', 'op1');
        $header = $this->bearer($operator);
        User::whereKey($operator->id)->update(['aktif' => false]);

        $this->withHeaders($header)->getJson('/api/padi-masuk')
            ->assertStatus(401)
            ->assertJsonPath('message', 'Akun nonaktif. Hubungi Pemilik.');
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    // --- Token kedaluwarsa

    public function test_token_kedaluwarsa_setelah_masa_berlaku(): void
    {
        $operator = $this->buat('operator', 'op1');
        $header = $this->bearer($operator);

        $this->withHeaders($header)->getJson('/api/me')->assertOk();

        $this->travel(8)->days();
        $this->refreshApplication();

        $this->withHeaders($header)->getJson('/api/me')->assertStatus(401);
    }

    // --- Pembatasan percobaan login

    public function test_login_salah_berulang_dibatasi_429(): void
    {
        $this->buat('operator', 'op1');

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/login', ['username' => 'op1', 'password' => 'salah'])->assertStatus(401);
        }

        $this->postJson('/api/login', ['username' => 'op1', 'password' => 'rahasia123'])
            ->assertStatus(429)
            ->assertJsonPath('success', false)
            ->assertHeader('Retry-After');
    }

    public function test_batas_login_per_username_tidak_mengunci_username_lain(): void
    {
        $this->buat('operator', 'op1');
        $this->buat('operator', 'op2');

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/login', ['username' => 'op1', 'password' => 'salah']);
        }

        $this->postJson('/api/login', ['username' => 'op2', 'password' => 'rahasia123'])->assertOk();
    }

    // --- Zona waktu: tanggal lokal (WIB) tidak boleh dianggap masa depan

    public function test_tanggal_hari_ini_wib_diterima_dini_hari(): void
    {
        // 18:30 UTC tanggal 27 = 01:30 WIB tanggal 28
        Carbon::setTestNow(Carbon::parse('2026-10-27 18:30:00', 'UTC'));

        $pelanggan = Pelanggan::create(['nama' => 'Pak Budi', 'tipe_pelanggan' => 'petani']);
        $kelas = KelasPadi::create(['nama_kelas' => 'Premium']);
        Sanctum::actingAs($this->buat('operator', 'op1'));

        $this->postJson('/api/padi-masuk', [
            'tanggal' => '2026-10-28',
            'pelanggan_id' => $pelanggan->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 50,
        ])->assertCreated();

        $this->postJson('/api/padi-masuk', [
            'tanggal' => '2026-10-29',
            'pelanggan_id' => $pelanggan->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 50,
        ])->assertStatus(422)->assertJsonPath('errors.0.field', 'tanggal');

        Carbon::setTestNow();
    }
}
