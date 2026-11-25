<?php

namespace Tests\Feature;

use App\Models\Pelanggan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PelangganOperatorTest extends TestCase
{
    use RefreshDatabase;

    private function masukSebagai(string $role): User
    {
        $user = User::create([
            'nama' => 'Pengguna '.$role,
            'username' => $role.'_uji',
            'password' => 'rahasia123',
            'role' => $role,
            'aktif' => true,
        ]);
        Sanctum::actingAs($user);

        return $user;
    }

    private function data(array $ubah = []): array
    {
        return array_merge([
            'nama' => 'Pak Warsito',
            'kontak' => '081234567890',
            'tipe_pelanggan' => 'petani',
        ], $ubah);
    }

    public function test_tanpa_token_dapat_401(): void
    {
        $this->postJson('/api/pelanggan', $this->data())
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_operator_bisa_menambah_petani_dan_pembuatnya_tercatat(): void
    {
        $operator = $this->masukSebagai('operator');

        $id = $this->postJson('/api/pelanggan', $this->data())
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nama', 'Pak Warsito')
            ->assertJsonPath('data.tipe_pelanggan', 'petani')
            ->json('data.id');

        $this->assertDatabaseHas('pelanggan', ['id' => $id, 'dibuat_oleh' => $operator->id]);
    }

    public function test_operator_bisa_menambah_pengepul(): void
    {
        $this->masukSebagai('operator');

        $this->postJson('/api/pelanggan', $this->data(['tipe_pelanggan' => 'pengepul']))
            ->assertCreated()
            ->assertJsonPath('data.tipe_pelanggan', 'pengepul');
    }

    public function test_operator_tidak_boleh_membuat_milik_huller(): void
    {
        $this->masukSebagai('operator');

        $this->postJson('/api/pelanggan', $this->data(['tipe_pelanggan' => 'milik_huller']))
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'tipe_pelanggan')
            ->assertJsonPath('errors.0.message', 'Operator hanya dapat menambah pelanggan bertipe petani atau pengepul');

        $this->assertDatabaseCount('pelanggan', 0);
    }

    public function test_owner_tetap_bisa_membuat_milik_huller(): void
    {
        $this->masukSebagai('owner');

        $this->postJson('/api/pelanggan', $this->data(['nama' => 'Huller Sendiri', 'tipe_pelanggan' => 'milik_huller']))
            ->assertCreated()
            ->assertJsonPath('data.tipe_pelanggan', 'milik_huller');
    }

    public function test_operator_tidak_bisa_ubah_hapus_atau_melihat_detail(): void
    {
        $pelanggan = Pelanggan::create($this->data());
        $this->masukSebagai('operator');

        $this->putJson('/api/pelanggan/'.$pelanggan->id, $this->data(['nama' => 'Diubah']))->assertStatus(403);
        $this->deleteJson('/api/pelanggan/'.$pelanggan->id)->assertStatus(403);
        $this->getJson('/api/pelanggan/'.$pelanggan->id)->assertStatus(403);
        $this->getJson('/api/pelanggan/'.$pelanggan->id.'/riwayat-transaksi')->assertStatus(403);

        $this->assertDatabaseHas('pelanggan', ['id' => $pelanggan->id, 'nama' => 'Pak Warsito']);
    }

    public function test_duplikat_nama_dan_kontak_ditolak(): void
    {
        $this->masukSebagai('operator');
        $this->postJson('/api/pelanggan', $this->data())->assertCreated();

        // Huruf besar/kecil pada nama tidak membedakan
        $this->postJson('/api/pelanggan', $this->data(['nama' => 'pak warsito']))
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'nama');

        $this->assertDatabaseCount('pelanggan', 1);
    }

    public function test_nama_sama_dengan_kontak_berbeda_atau_kosong_diizinkan(): void
    {
        $this->masukSebagai('operator');
        $this->postJson('/api/pelanggan', $this->data())->assertCreated();

        $this->postJson('/api/pelanggan', $this->data(['kontak' => '081111111111']))->assertCreated();
        $this->postJson('/api/pelanggan', $this->data(['kontak' => null]))->assertCreated();

        $this->assertDatabaseCount('pelanggan', 3);
    }

    public function test_pelanggan_terhapus_tidak_dihitung_duplikat(): void
    {
        Pelanggan::create($this->data())->delete();
        $this->masukSebagai('operator');

        $this->postJson('/api/pelanggan', $this->data())->assertCreated();
    }

    public function test_owner_melihat_siapa_pembuat_pelanggan(): void
    {
        $operator = $this->masukSebagai('operator');
        $id = $this->postJson('/api/pelanggan', $this->data())->json('data.id');

        $this->masukSebagai('owner');

        $this->getJson('/api/pelanggan/'.$id)
            ->assertOk()
            ->assertJsonPath('data.dibuat_oleh.id', $operator->id)
            ->assertJsonPath('data.dibuat_oleh.role', 'operator');
    }
}
