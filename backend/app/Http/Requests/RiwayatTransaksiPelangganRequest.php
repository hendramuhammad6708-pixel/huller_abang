<?php

namespace App\Http\Requests;

use App\Models\PadiMasuk;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RiwayatTransaksiPelangganRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', Rule::in(PadiMasuk::daftarStatus())],
            'tanggal_dari' => ['nullable', 'date_format:Y-m-d'],
            'tanggal_sampai' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:tanggal_dari'],
            'page' => ['nullable', 'integer', 'min:1'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'status.in' => 'Status harus masuk, dijemur, siap_giling, selesai_giling, atau void',
            'tanggal_dari.date_format' => 'Format tanggal harus YYYY-MM-DD',
            'tanggal_sampai.date_format' => 'Format tanggal harus YYYY-MM-DD',
            'tanggal_sampai.after_or_equal' => 'Tanggal sampai tidak boleh sebelum tanggal dari',
            'limit.integer' => 'Limit harus berupa angka',
            'limit.min' => 'Limit minimal 1',
            'limit.max' => 'Limit maksimal 100',
            'page.integer' => 'Halaman harus berupa angka',
            'page.min' => 'Halaman minimal 1',
        ];
    }
}
