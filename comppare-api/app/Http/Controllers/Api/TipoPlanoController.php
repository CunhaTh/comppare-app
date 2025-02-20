<?php

namespace App\Http\Controllers\Api;

use App\Http\Util\Helper;
use App\Models\TipoPlano;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;


class TipoPlanoController extends Controller
{
    private $codes = [];
    public function __construct()
    {
        $this->codes = Helper::getHttpCodes();
    }
    /**
     * Display a listing of the resource.
     */
    public function index() : object
    {
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
            'data' => TipoPlano::all()

        ];
        return response()->json($response);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function cadastrar(Request $request)
    {
        $tipoPlano = TipoPlano::create([
            'nome' => $request->nome
        ]);
        if (isset($tipoPlano->id)) {
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200]
            ];
        } else {

            $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        }
        return response()->json($response);
    }

    /**
     * Display the specified resource.
     */
    public function getTipoPlano(Request $request)
    {
        $tipoPlano = TipoPlano::find($request->idTipoPlano);
        isset($tipoPlano->id) ?
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200],
                'data' => $tipoPlano
            ] :  $response = [
            'codRetorno' => 404,
            'message' => $this->codes[404]
        ];
        return response()->json($response);
    }

    /**
     * Update the specified resource in storage.
     */
    public function atualizarDados(Request $request)
    {
        $tipoPlano = TipoPlano::find($request->idTipoPlano);

        if (isset($tipoPlano->id)) {
            $tipoPlano->nome = $request->nome;
            $tipoPlano->save();
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200]
            ];
        } else {
            $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        }

        return response()->json($response);
    }
    public function atualizarStatus(Request $request)
    {
        $tipoPlano = TipoPlano::find($request->idTipoPlano);
        if (isset($tipoPlano->id)) {
            $tipoPlano->status = $request->status;
            $tipoPlano->save();
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200]
            ];
        } else {

            $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        }
        return response()->json($response);
    }
}
