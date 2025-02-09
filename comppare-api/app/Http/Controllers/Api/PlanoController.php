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

    public function index()
    {
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
            'data' => Planos::all()

        ];
        return response()->json($response);
    }

    public function cadastrarPlano(Request $request)
    {
        $plano = Planos::create([
            'nome' => $request->nomePlano,
            'descricao' => $request->descricao,
            'valor' => $request->valor
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


    public function getPlano(Request $request)
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

    public function atualizarDados(Request $request, $id)
    {
        $plano = Planos::findOrFail($id);
        $plano->update($request->all());
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200]
        ];
        return response()->json($response);
    }

    public function atualizarStatus($id)
    {
        //Falta criar o campo status para desativar logicamente
        Planos::findOrFail($id)->delete();
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
        ];
        return response()->json($response);
    }
}
