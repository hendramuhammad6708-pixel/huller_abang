<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\PengaturanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PengaturanTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(PengaturanSeeder::class);
        $this->sebagaiOwner();
    }

    // Modul pengaturan terkunci: butuh token + role owner
    private function sebagaiOwner(): void
    {
        Sanctum::actingAs(User::create([
            'nama' => 'Pemilik Huller',
            'username' => 'pemilik',
            'password' => 'rahasia123',
            'role' => 'owner',
            'aktif' => true,
        ]));
    }

    public function test_ambil_pengaturan_default(): void
    {
        $this->getJson('/api/pengaturan')
            ->assertOk()
            ->assertJsonPath('data.persen_upah', 5)
            ->assertJsonPath('data.persen_hak_operator', 5);
    }

    public function test_ubah_kedua_nilai(): void
    {
        $this->putJson('/api/pengaturan', ['persen_upah' => 6, 'persen_hak_operator' => 2.5])
            ->assertOk()
            ->assertJsonPath('data.persen_upah', 6)
            ->assertJsonPath('data.persen_hak_operator', 2.5);

        $this->getJson('/api/pengaturan')->assertJsonPath('data.persen_hak_operator', 2.5);
    }

    public function test_ubah_satu_nilai_saja(): void
    {
        $this->putJson('/api/pengaturan', ['persen_upah' => 7])
            ->assertOk()
            ->assertJsonPath('data.persen_upah', 7)
            ->assertJsonPath('data.persen_hak_operator', 5);
    }

    public function test_nilai_tidak_valid_ditolak(): void
    {
        foreach ([101, -1, 'abc', ''] as $nilai) {
            $this->putJson('/api/pengaturan', ['persen_upah' => $nilai])
                ->assertStatus(422)
                ->assertJsonPath('success', false);
        }
    }

    public function test_body_kosong_ditolak(): void
    {
        $this->putJson('/api/pengaturan', [])->assertStatus(422);
    }

    public function test_seeder_aman_dijalankan_ulang_dan_tidak_menimpa_perubahan(): void
    {
        $this->putJson('/api/pengaturan', ['persen_upah' => 8])->assertOk();

        $this->seed(PengaturanSeeder::class);

        $this->getJson('/api/pengaturan')->assertJsonPath('data.persen_upah', 8);
        $this->assertDatabaseCount('pengaturan', 2);
    }
}
