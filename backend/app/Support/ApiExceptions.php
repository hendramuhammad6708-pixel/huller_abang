<?php

namespace App\Support;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

class ApiExceptions
{
    public static function daftarkan(Exceptions $exceptions): void
    {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request, Throwable $e) => $request->is('api/*') || $request->expectsJson()
        );

        $exceptions->render(function (ValidationException $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            $errors = [];
            foreach ($e->errors() as $field => $messages) {
                foreach ($messages as $message) {
                    $errors[] = ['field' => $field, 'message' => $message];
                }
            }

            return ApiResponse::gagal('Data tidak valid', 422, $errors);
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::gagal('Sesi berakhir atau token tidak diberikan.', 401);
        });

        $exceptions->render(function (NotFoundHttpException $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::gagal('Data atau endpoint tidak ditemukan', 404);
        });

        $exceptions->render(function (MethodNotAllowedHttpException $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::gagal('Metode HTTP tidak diizinkan untuk alamat ini', 405);
        });
    }
}
