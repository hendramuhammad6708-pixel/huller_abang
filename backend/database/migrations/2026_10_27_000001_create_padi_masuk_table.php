<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('padi_masuk', function (Blueprint $table) {
            $table->id();
            $table->string('nomor_transaksi', 30)->nullable()->unique();
            $table->date('tanggal')->index();
            $table->foreignId('pelanggan_id')->constrained('pelanggan');
            $table->foreignId('kelas_padi_id')->constrained('kelas_padi');
            $table->decimal('berat_basah_kg', 10, 2);
            $table->string('catatan', 255)->nullable();

            // masuk -> dijemur -> siap_giling -> selesai_giling (atau void)
            $table->string('status_transaksi', 20)->default('masuk')->index();

            // Diisi saat penjemuran selesai
            $table->decimal('berat_kering_kg', 10, 2)->nullable();
            $table->decimal('persen_susut', 5, 2)->nullable();
            $table->date('tanggal_selesai_giling')->nullable();

            // Pembatalan (void): data tidak dihapus, hanya ditandai
            $table->string('void_reason', 255)->nullable();
            $table->foreignId('void_by')->nullable()->constrained('users');
            $table->timestamp('voided_at')->nullable();

            $table->foreignId('dibuat_oleh')->nullable()->constrained('users');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('padi_masuk');
    }
};
