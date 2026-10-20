<?php

use App\Http\Controllers\AuthController;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

// Cek server dan database hidup  ->  GET /api/health
Route::get('/health', function () {
    try {
        DB::select('select 1');

        return ApiResponse::sukses('ok', ['database' => 'terhubung']);
    } catch (Throwable $e) {
        return ApiResponse::gagal('Database tidak terhubung', 500);
    }
});

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
});

// Daftar route modul: tiap modul menambah barisnya di bawah ini
