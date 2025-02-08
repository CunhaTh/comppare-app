<?php

namespace Database\Factories;

use App\Models\Planos;
use Illuminate\Database\Eloquent\Factories\Factory;
use Faker\Factory as Faker;

class PlanosFactory extends Factory
{
    protected $model = Planos::class;

    public function definition(): array
    {
        $faker = Faker::create('pt_BR'); // Set Brazilian locale for CPF

        return [
            'nome' => ucfirst($faker->randomElement(['Plano Básico', 'Plano Padrão', 'Plano Premium', 'Plano Avançado'])),
            'descricao' => $faker->sentence(10), // 10 palavras de uma frase aleatória
            'valor' => $faker->randomFloat(2, 10, 500) // Um valor aleatório entre 10 e 500 com 2 casas decimais

        ];
    }
}
