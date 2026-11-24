<?php

namespace Tests\Feature;

use App\Models\KelasPadi;
use App\Models\PadiMasuk;
use App\Models\Pelanggan;
use App\Models\Pengaturan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DashboardSummaryTest extends TestCase
{
    use RefreshDatabase;

    private function buatUser(string $role, bool $aktif = true): User
    {
        return User::create([
            'nama' => 'Pengguna '.$role,
            'username' => $role.'_'.random_int(1, 999999),
            'password' => 'rahasia123',
            'role' => $role,
            'aktif' => $aktif,
        ]);
    }

    public function test_membutuhkan_autentikasi(): void
    {
        $this->getJson('/api/dashboard/summary')->assertStatus(401);
    }

    public function test_operator_juga_bisa_melihat_ringkasan(): void
    {
        Sanctum::actingAs($this->buatUser('operator'));

        $this->getJson('/api/dashboard/summary')->assertOk();
    }

    public function test_ringkasan_menghitung_data_aktif_dan_mengecualikan_terhapus(): void
    {
        $owner = $this->buatUser('owner');
        $this->buatUser('operator');
        $this->buatUser('operator', aktif: false);

        Pelanggan::create(['nama' => 'Petani A', 'tipe_pelanggan' => 'petani']);
        Pelanggan::create(['nama' => 'Pengepul B', 'tipe_pelanggan' => 'pengepul']);
        Pelanggan::create(['nama' => 'Pengepul C', 'tipe_pelanggan' => 'pengepul']);
        Pelanggan::create(['nama' => 'Terhapus D', 'tipe_pelanggan' => 'petani'])->delete();

        $kelas = KelasPadi::create(['nama_kelas' => 'Super']);
        Pengaturan::create(['kunci' => 'harga_per_kg', 'nilai' => '12000']);

        $petani = Pelanggan::where('nama', 'Petani A')->first();
        $kemarin = now()->subDay()->toDateString();
        $hariIni = now()->toDateString();

        PadiMasuk::create([
            'tanggal' => $hariIni,
            'pelanggan_id' => $petani->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 100,
            'catatan' => null,
            'status_transaksi' => PadiMasuk::STATUS_MASUK,
        ]);
        PadiMasuk::create([
            'tanggal' => $hariIni,
            'pelanggan_id' => $petani->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 50.5,
            'catatan' => null,
            'status_transaksi' => PadiMasuk::STATUS_MASUK,
        ]);
        PadiMasuk::create([
            'tanggal' => $kemarin,
            'pelanggan_id' => $petani->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 200,
            'catatan' => null,
            'status_transaksi' => PadiMasuk::STATUS_DIJEMUR,
        ]);
        PadiMasuk::create([
            'tanggal' => $kemarin,
            'pelanggan_id' => $petani->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 75,
            'catatan' => null,
            'status_transaksi' => PadiMasuk::STATUS_SIAP_GILING,
        ]);

        Sanctum::actingAs($owner);

        $this->getJson('/api/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.total_operator', 2)
            ->assertJsonPath('data.operator_aktif', 1)
            ->assertJsonPath('data.total_pelanggan', 3)
            ->assertJsonPath('data.pelanggan_per_tipe.pengepul', 2)
            ->assertJsonPath('data.pelanggan_per_tipe.petani', 1)
            ->assertJsonPath('data.pelanggan_per_tipe.milik_huller', 0)
            ->assertJsonPath('data.total_kelas_padi', 1)
            ->assertJsonPath('data.total_pengaturan', 1)
            ->assertJsonPath('data.padi_masuk.jumlah_transaksi', 4)
            ->assertJsonPath('data.padi_masuk.total_berat_kg', 425.5)
            ->assertJsonPath('data.padi_masuk.hari_ini.jumlah_transaksi', 2)
            ->assertJsonPath('data.padi_masuk.hari_ini.total_berat_kg', 150.5)
            ->assertJsonPath('data.penjemuran.sedang_dijemur', 1)
            ->assertJsonPath('data.penjemuran.siap_giling', 1)
            ->assertJsonPath('data.transaksi', 4)
            ->assertJsonPath('data.stok', 0);
    }

    public function test_database_kosong_menghasilkan_nol_di_semua_kolom(): void
    {
        Sanctum::actingAs($this->buatUser('owner'));

        $this->getJson('/api/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.total_operator', 0)
            ->assertJsonPath('data.operator_aktif', 0)
            ->assertJsonPath('data.total_pelanggan', 0)
            ->assertJsonPath('data.padi_masuk.jumlah_transaksi', 0)
            ->assertJsonPath('data.padi_masuk.total_berat_kg', 0)
            ->assertJsonPath('data.padi_masuk.hari_ini.jumlah_transaksi', 0)
            ->assertJsonPath('data.penjemuran.sedang_dijemur', 0)
            ->assertJsonPath('data.penjemuran.siap_giling', 0)
            ->assertJsonPath('data.transaksi', 0)
            ->assertJsonPath('data.stok', 0);
    }
}
