<?php

namespace App\Http\Middleware;

use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Symfony\Component\HttpFoundation\Response;

/**
 * Menolak akun yang dinonaktifkan Pemilik walau tokennya masih ada.
 * Token juga dicabut saat akun dinonaktifkan (OperatorController); middleware
 * ini jaring pengaman bila status diubah lewat jalur lain.
 */
class PastikanAkunAktif
{
    public function handle(Request $request, Closure $next): Response
    {
        $pengguna = $request->user();

        if ($pengguna && ! $pengguna->aktif) {
            $token = $pengguna->currentAccessToken();
            if ($token instanceof PersonalAccessToken) {
                $token->delete();
            }

            return ApiResponse::gagal('Akun nonaktif. Hubungi Pemilik.', 401);
        }

        return $next($request);
    }
}
