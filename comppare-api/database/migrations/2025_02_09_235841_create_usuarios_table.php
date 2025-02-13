<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->string('nome');
            $table->string('cpf')->unique();
            $table->string('senha');
            $table->string('telefone');
            $table->boolean('status')->default(true);
            $table->unsignedBigInteger('idPlano'); //
            $table->foreign('idPlano')->references('id')->on('planos');
            $table->timestamp('dataLimiteCompra')->nullable();
            $table->timestamp('dataUltimoPagamento')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('usuarios');
    }
};
