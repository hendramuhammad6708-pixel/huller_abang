<?php

use App\Support\ApiResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

// Cek server dan database hidup  ->  GET /api/health
Route::get('/health', function () {
    try {
        DB::select('select 1');

        return ApiResponse::sukses('ok', ['database' => 'terhubung']);
    } catch (\Throwable $e) {
        return ApiResponse::gagal('Database tidak terhubung', 500);
    }
});

// Daftar route modul: tiap modul menambah barisnya di bawah ini
