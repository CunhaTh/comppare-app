<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Util\Helper;
use Illuminate\Http\Request;
use App\Models\Cupom;

class CupomController extends Controller
{
    private $codes = [];
    //teste server
    private int $gratuidade = 0;

    public function __construct()
    {
        $this->codes = Helper::getHttpCodes();
        $this->gratuidade = config('app.validadeCupom');
    }

    public function index() : object
    {
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
            'data' => Cupom::all()

        ];
        return response()->json($response);
    }

    public function saveTicket(Request $request) : object
    {
        $cupom = Cupom::create([
            'cupom' => $request->cupom,
            'percentualDesconto' => $request->percentualDesconto

        ]);
        if (isset($cupom->id)) {
            $cupom->dataExpiracao = $cupom->created_at->addDays($request->quantidadeDias);
            $cupom->save();
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

    public function getTicketDiscount(Request $request) : object
    {
        $cupom = Cupom::find($request->idCupom);
        isset($cupom->id) ?
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200],
                'data' => $cupom
            ] :  $response = [
                'codRetorno' => 404,
                'message' => $this->codes[404]
            ];
        return response()->json($response);
    }

    public function atualizarDados(Request $request) : object
    {
        $cupom = Cupom::findOrFail($request->idCupom);

        if (isset($cupom->id)) {
            $cupom->cupom = $request->cupom;
            $cupom->percentualDesconto = $request->percentualDesconto;
            $cupom->save();
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

    public function atualizarStatus(Request $request) : object
    {
        $cupom = Cupom::findOrFail($request->idCupom);
        if (isset($cupom->id)) {
            $cupom->status = $request->status;
            $cupom->save();
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
