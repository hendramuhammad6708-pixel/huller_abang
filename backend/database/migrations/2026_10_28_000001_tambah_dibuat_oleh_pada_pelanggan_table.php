<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Operator boleh menambah pelanggan; kolom ini mencatat siapa pembuatnya
        // agar owner bisa meninjau data yang dibuat operator. Null = data lama.
        Schema::table('pelanggan', function (Blueprint $table) {
            $table->foreignId('dibuat_oleh')->nullable()->after('tipe_pelanggan')->constrained('users');
        });
    }

    public function down(): void
    {
        Schema::table('pelanggan', function (Blueprint $table) {
            $table->dropConstrainedForeignId('dibuat_oleh');
        });
    }
};
