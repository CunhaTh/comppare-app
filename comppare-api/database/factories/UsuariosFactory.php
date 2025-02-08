<?php

namespace Database\Factories;

use App\Models\Usuarios;
use Illuminate\Database\Eloquent\Factories\Factory;
use Faker\Factory as Faker;

class UsuariosFactory extends Factory
{
    protected $model = Usuarios::class;

    public function definition(): array
    {
        $faker = Faker::create('pt_BR'); // Set Brazilian locale for CPF

        return [
            'nome' => $faker->name,
            'cpf' => $faker->unique()->numerify('###########'), // Generate fake CPF
            'senha' => base64_encode('12345')
        ];
    }
}
