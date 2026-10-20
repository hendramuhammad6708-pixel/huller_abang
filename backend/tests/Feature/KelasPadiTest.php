<?php

namespace Tests\Feature;

use App\Models\KelasPadi;
use App\Models\User;
use Database\Seeders\KelasPadiSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class KelasPadiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->sebagaiOwner();
    }

    // Modul kelas padi terkunci: butuh token + role owner
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

    public function test_daftar_berisi_kelas_1_dan_2(): void
    {
        $this->seed(KelasPadiSeeder::class);

        $this->getJson('/api/kelas-padi')
            ->assertOk()
            ->assertJsonCount(2, 'data.items')
            ->assertJsonPath('data.items.0.nama_kelas', 'Kelas 1')
            ->assertJsonPath('data.meta.total', 2);
    }

    public function test_seeder_tidak_membuat_data_dobel(): void
    {
        $this->seed(KelasPadiSeeder::class);
        $this->seed(KelasPadiSeeder::class);

        $this->assertDatabaseCount('kelas_padi', 2);
    }

    public function test_tambah_kelas(): void
    {
        $this->postJson('/api/kelas-padi', ['nama_kelas' => 'Kelas 3'])
            ->assertStatus(201)
            ->assertJsonStructure(['data' => ['id']]);

        $this->assertDatabaseHas('kelas_padi', ['nama_kelas' => 'Kelas 3']);
    }

    public function test_nama_dobel_dan_kosong_ditolak(): void
    {
        KelasPadi::create(['nama_kelas' => 'Kelas 1']);

        $this->postJson('/api/kelas-padi', ['nama_kelas' => 'Kelas 1'])
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'nama_kelas');

        $this->postJson('/api/kelas-padi', ['nama_kelas' => '  '])->assertStatus(422);
    }

    public function test_ubah_kelas_dengan_nama_sendiri_tidak_dianggap_dobel(): void
    {
        $kelas = KelasPadi::create(['nama_kelas' => 'Kelas 1']);

        $this->putJson('/api/kelas-padi/'.$kelas->id, ['nama_kelas' => 'Kelas 1'])->assertOk();
        $this->putJson('/api/kelas-padi/'.$kelas->id, ['nama_kelas' => 'Kelas Super'])->assertOk();

        $this->assertDatabaseHas('kelas_padi', ['id' => $kelas->id, 'nama_kelas' => 'Kelas Super']);
    }

    public function test_hapus_kelas_dan_id_tidak_ada(): void
    {
        $kelas = KelasPadi::create(['nama_kelas' => 'Kelas X']);

        $this->deleteJson('/api/kelas-padi/'.$kelas->id)->assertOk();
        $this->assertDatabaseMissing('kelas_padi', ['id' => $kelas->id]);

        $this->deleteJson('/api/kelas-padi/'.$kelas->id)->assertStatus(404);
        $this->putJson('/api/kelas-padi/'.$kelas->id, ['nama_kelas' => 'Y'])->assertStatus(404);
    }
}
