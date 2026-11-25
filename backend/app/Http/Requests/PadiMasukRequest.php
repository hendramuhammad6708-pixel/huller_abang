<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class PadiMasukRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tanggal' => ['bail', 'required', 'date_format:Y-m-d', 'before_or_equal:today'],
            // Pelanggan yang sudah dihapus tidak boleh dipilih untuk transaksi baru
            'pelanggan_id' => [
                'bail', 'required', 'integer',
                Rule::exists('pelanggan', 'id')->whereNull('deleted_at'),
            ],
            'kelas_padi_id' => ['bail', 'required', 'integer', 'exists:kelas_padi,id'],
            'berat_basah_kg' => ['bail', 'required', 'numeric', 'gt:0', 'max:99999999.99'],
            'catatan' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'tanggal.required' => 'Tanggal wajib diisi',
            'tanggal.date_format' => 'Format tanggal harus YYYY-MM-DD',
            'tanggal.before_or_equal' => 'Tanggal tidak boleh di masa depan',
            'pelanggan_id.required' => 'Pelanggan wajib dipilih',
            'pelanggan_id.integer' => 'Pelanggan tidak valid',
            'pelanggan_id.exists' => 'Pelanggan tidak ditemukan',
            'kelas_padi_id.required' => 'Kelas padi wajib dipilih',
            'kelas_padi_id.integer' => 'Kelas padi tidak valid',
            'kelas_padi_id.exists' => 'Kelas padi tidak ditemukan',
            'berat_basah_kg.required' => 'Berat wajib diisi',
            'berat_basah_kg.numeric' => 'Berat harus berupa angka',
            'berat_basah_kg.gt' => 'Berat harus lebih dari 0',
            'berat_basah_kg.max' => 'Berat terlalu besar',
            'catatan.max' => 'Catatan maksimal 255 karakter',
        ];
    }
}
