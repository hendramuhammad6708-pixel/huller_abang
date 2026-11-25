<?php

namespace App\Http\Requests;

use App\Models\Pelanggan;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class PelangganRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        // Operator hanya boleh membuat petani atau pengepul
        $tipeBoleh = $this->user()?->role === 'operator'
            ? Pelanggan::TIPE_OPERATOR
            : Pelanggan::TIPE;

        return [
            'nama' => ['bail', 'required', 'string', 'max:100'],
            'kontak' => ['nullable', 'regex:/^\+?[0-9]{8,15}$/'],
            'tipe_pelanggan' => ['bail', 'required', Rule::in($tipeBoleh)],
        ];
    }

    public function messages(): array
    {
        return [
            'nama.required' => 'Nama wajib diisi',
            'nama.string' => 'Nama harus berupa teks',
            'nama.max' => 'Nama maksimal 100 karakter',
            'kontak.regex' => 'Kontak hanya angka, 8-15 digit',
            'tipe_pelanggan.required' => 'Tipe pelanggan wajib diisi',
            'tipe_pelanggan.in' => $this->user()?->role === 'operator'
                ? 'Operator hanya dapat menambah pelanggan bertipe petani atau pengepul'
                : 'Tipe harus pengepul, petani, atau milik_huller',
        ];
    }
}
