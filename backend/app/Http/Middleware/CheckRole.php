<?php

namespace App\Http\Middleware;

use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $pengguna = $request->user();

        if (! $pengguna || ! in_array($pengguna->role, $roles, true)) {
            return ApiResponse::gagal('Anda tidak memiliki akses untuk resource ini.', 403);
        }

        return $next($request);
    }
}
