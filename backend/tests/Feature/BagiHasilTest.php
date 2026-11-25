<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\PengaturanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BagiHasilTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(PengaturanSeeder::class);
        Sanctum::actingAs(User::create([
            'nama' => 'Operator Satu',
            'username' => 'operator1',
            'password' => 'rahasia123',
            'role' => 'operator',
            'aktif' => true,
        ]));
    }

    public function test_hitung_dengan_persen_dari_request(): void
    {
        // upah 5% x 1000 = 50; operator 5% x 50 = 2.5; huller 47.5; saldo 950
        $this->postJson('/api/bagi-hasil', [
            'berat_bersih_kg' => 1000,
            'persen_upah' => 5,
            'persen_hak_operator' => 5,
        ])
            ->assertOk()
            ->assertJsonPath('data.upah_kg', 50)
            ->assertJsonPath('data.operator_kg', 2.5)
            ->assertJsonPath('data.huller_kg', 47.5)
            ->assertJsonPath('data.saldo_pelanggan_kg', 950);
    }

    public function test_persen_default_dari_pengaturan(): void
    {
        $this->postJson('/api/bagi-hasil', ['berat_bersih_kg' => 200])
            ->assertOk()
            ->assertJsonPath('data.persen_upah', 5)
            ->assertJsonPath('data.upah_kg', 10)
            ->assertJsonPath('data.operator_kg', 0.5)
            ->assertJsonPath('data.huller_kg', 9.5)
            ->assertJsonPath('data.saldo_pelanggan_kg', 190);
    }

    public function test_pembulatan_dua_desimal(): void
    {
        // 123.45 x 7% = 8.6415 -> 8.64; operator 3% x 8.64 = 0.2592 -> 0.26
        $this->postJson('/api/bagi-hasil', [
            'berat_bersih_kg' => 123.45,
            'persen_upah' => 7,
            'persen_hak_operator' => 3,
        ])
            ->assertOk()
            ->assertJsonPath('data.upah_kg', 8.64)
            ->assertJsonPath('data.operator_kg', 0.26)
            ->assertJsonPath('data.huller_kg', 8.38)
            ->assertJsonPath('data.saldo_pelanggan_kg', 114.81);
    }

    public function test_validasi(): void
    {
        $this->postJson('/api/bagi-hasil', [])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'berat_bersih_kg');
        $this->postJson('/api/bagi-hasil', ['berat_bersih_kg' => 0])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'berat_bersih_kg');
        $this->postJson('/api/bagi-hasil', ['berat_bersih_kg' => 100, 'persen_upah' => 101])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'persen_upah');
    }
}
