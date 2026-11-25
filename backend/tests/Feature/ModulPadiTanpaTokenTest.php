<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ModulPadiTanpaTokenTest extends TestCase
{
    use RefreshDatabase;

    // Modul padi masuk, penjemuran, dan bagi hasil wajib memakai token Sanctum.
    private const ALAMAT = [
        ['GET', '/api/padi-masuk'],
        ['POST', '/api/padi-masuk'],
        ['GET', '/api/padi-masuk/1'],
        ['PUT', '/api/padi-masuk/1'],
        ['POST', '/api/padi-masuk/1/void'],
        ['POST', '/api/padi-masuk/1/selesai-giling'],
        ['GET', '/api/padi-masuk/1/log'],
        ['GET', '/api/penjemuran'],
        ['POST', '/api/padi-masuk/1/penjemuran'],
        ['PUT', '/api/padi-masuk/1/penjemuran'],
        ['POST', '/api/penjemuran/1/mulai'],
        ['POST', '/api/penjemuran/1/selesai'],
        ['POST', '/api/bagi-hasil'],
    ];

    public function test_tanpa_token_dapat_401(): void
    {
        foreach (self::ALAMAT as [$metode, $alamat]) {
            $this->json($metode, $alamat, [])
                ->assertStatus(401)
                ->assertJsonPath('success', false);
        }
    }
}
