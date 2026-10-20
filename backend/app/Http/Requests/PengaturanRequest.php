<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PengaturanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    // Boleh mengirim salah satu atau keduanya, tapi minimal satu.
    public function rules(): array
    {
        return [
            'persen_upah' => ['bail', 'required_without:persen_hak_operator', 'numeric', 'between:0,100'],
            'persen_hak_operator' => ['bail', 'required_without:persen_upah', 'numeric', 'between:0,100'],
        ];
    }

    public function messages(): array
    {
        $angka = 'Harus berupa angka antara 0 sampai 100';

        return [
            'persen_upah.required_without' => 'Kirim persen_upah dan/atau persen_hak_operator',
            'persen_hak_operator.required_without' => 'Kirim persen_upah dan/atau persen_hak_operator',
            'persen_upah.numeric' => $angka,
            'persen_upah.between' => $angka,
            'persen_hak_operator.numeric' => $angka,
            'persen_hak_operator.between' => $angka,
        ];
    }
}
