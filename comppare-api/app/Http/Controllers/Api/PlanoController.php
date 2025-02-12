<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Planos;
use App\Http\Util\Helper;

class PlanoController extends Controller
{
    private $codes = [];
    public function __construct()
    {
        $this->codes = Helper::getHttpCodes();
    }

    public function index() : object
    {
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
            'data' => Planos::all()

        ];
        return response()->json($response);
    }

    public function cadastrarPlano(Request $request) : object
    {
        $plano = Planos::create([
            'nome' => $request->nome,
            'descricao' => $request->descricao,
            'valor' => $request->valor,
            'idTipoPlano' => $request->tipoPlano,
            'tempoGratuidade' => $request->gratuidade
        ]);
        isset($plano->id) ?
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200]
            ] :  $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        return response()->json($response);
    }


    public function getPlano(Request $request) : object
    {
        $plano = Planos::find($request->idPlano);
        isset($plano->id) ?
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200],
                'data' => $plano
            ] :  $response = [
                'codRetorno' => 404,
                'message' => $this->codes[404]
            ];
        return response()->json($response);
    }

    public function atualizarDados(Request $request): object
    {
        $plano = Planos::findOrFail($request->idPlano);
        if(isset($plano->id)){
            $plano->nome = $request->nomePlano;
            $plano->descricao = $request->descricao;
            $plano->valor = $request->valor;
            $plano->tempoGratuidade = $request->gratuidade;
            $plano->idTipoPlano = $request->tipoPlano;
            $plano->save();
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200]
            ];
        }else{
            $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        }

        return response()->json($response);
    }

    public function atualizarStatus(Request $request) : object
    {
        $plano = Planos::findOrFail($request->idPlano);
        if(isset($plano->id)){
            $plano->status = $request->status;
            $plano->save();
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200]
            ];
        }else{
            $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        }
        return response()->json($response);

    }
}
