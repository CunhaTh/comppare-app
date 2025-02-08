<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Faker\Factory as Faker;

class UsuarioSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $faker = Faker::create('pt_BR'); // Brazilian locale for CPF format

        foreach (range(1, 10) as $index) {
            DB::table('usuarios')->insert([
                'cpf' => $faker->unique()->cpf(false), // Generates CPF without formatting
                'nome' => $faker->name,
                'senha' => base64_encode('12345'),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}
