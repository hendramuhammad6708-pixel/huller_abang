<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ModulTerkunciTest extends TestCase
{
    use RefreshDatabase;

    // Alamat modul yang wajib terkunci (role owner)
    private const ALAMAT = [
        ['GET', '/api/pelanggan'],
        ['POST', '/api/pelanggan'],
        ['GET', '/api/pengaturan'],
        ['PUT', '/api/pengaturan'],
        ['GET', '/api/kelas-padi'],
        ['POST', '/api/kelas-padi'],
    ];

    public function test_tanpa_token_dapat_401(): void
    {
        foreach (self::ALAMAT as [$metode, $alamat]) {
            $this->json($metode, $alamat, [])
                ->assertStatus(401)
                ->assertJsonPath('success', false);
        }
    }

    public function test_tanpa_header_json_dapat_401_json_bukan_error(): void
    {
        // dulu 500 "Route [login] not defined" karena guest di-redirect ke route web
        $this->get('/api/pelanggan')
            ->assertStatus(401)
            ->assertHeader('Content-Type', 'application/json')
            ->assertJsonPath('success', false);
    }

    public function test_operator_mendapat_403(): void
    {
        Sanctum::actingAs(User::create([
            'nama' => 'Operator Satu',
            'username' => 'operator1',
            'password' => 'rahasia123',
            'role' => 'operator',
            'aktif' => true,
        ]));

        foreach (self::ALAMAT as [$metode, $alamat]) {
            $this->json($metode, $alamat, [])
                ->assertStatus(403)
                ->assertJsonPath('message', 'Anda tidak memiliki akses untuk resource ini.');
        }
    }

    public function test_login_dan_health_tetap_publik(): void
    {
        $this->getJson('/api/health')->assertOk();
        $this->postJson('/api/login', [])->assertStatus(422);
    }
}
