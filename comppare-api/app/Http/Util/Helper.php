<?php

namespace App\Http\Util;

class Helper
{
    /**
     * Retorna todos os códigos HTTP e suas descrições.
     *
     * @return array
     */
    public static function getHttpCodes()
    {
        return [
            100 => 'Continue',
            101 => 'Mudando Protocolos',
            102 => 'Processando',
            200 => 'OK',
            201 => 'Criado',
            202 => 'Aceito',
            203 => 'Informação Não Autoritativa',
            204 => 'Sem Conteúdo',
            205 => 'Redefinir Conteúdo',
            206 => 'Conteúdo Parcial',
            207 => 'Multi-Status',
            208 => 'Já Reportado',
            226 => 'IM Usado',
            300 => 'Múltiplas Opções',
            301 => 'Movido Permanentemente',
            302 => 'Encontrado',
            303 => 'Ver Outro',
            304 => 'Não Modificado',
            305 => 'Usar Proxy',
            307 => 'Redirecionamento Temporário',
            308 => 'Redirecionamento Permanente',
            400 => 'Requisição Inválida',
            401 => 'Não Autorizado',
            402 => 'Pagamento Requerido',
            403 => 'Acesso Restrito',
            404 => 'Não Encontrado',
            405 => 'Método Não Permitido',
            406 => 'Não Aceitável',
            407 => 'Autenticação de Proxy Requerida',
            408 => 'Tempo de Requisição Esgotado',
            409 => 'Dado já existente no banco de dados',
            410 => 'Desaparecido',
            411 => 'Comprimento Requerido',
            412 => 'Falha de Pré-Condição',
            413 => 'Carga Útil Muito Grande',
            414 => 'URI Muito Longa',
            415 => 'Tipo de Mídia Não Suportado',
            416 => 'Intervalo Não Satisfatório',
            417 => 'Falha na Expectativa',
            418 => 'Sou um bule de chá',
            421 => 'Requisição Desviada',
            422 => 'Entidade Não Processável',
            423 => 'Bloqueado',
            424 => 'Falha de Dependência',
            425 => 'Muito Cedo',
            426 => 'Atualização Requerida',
            428 => 'Pré-Condição Requerida',
            429 => 'Muitas Requisições',
            431 => 'Campos de Cabeçalho de Requisição Muito Grandes',
            451 => 'Indisponível por Razões Legais',
            500 => 'Erro Interno do Servidor',
            501 => 'Não Implementado',
            502 => 'Bad Gateway',
            503 => 'Serviço Indisponível',
            504 => 'Tempo de Espera do Gateway Esgotado',
            505 => 'Versão HTTP Não Suportada',
            506 => 'Variação Também Negocia',
            507 => 'Armazenamento Insuficiente',
            508 => 'Loop Detectado',
            510 => 'Não Estendido',
            511 => 'Autenticação de Rede Requerida',
            //Especificos do COMPPARE APP
            -1 => 'Error: Erro desconhecido',
            -2 => 'Error: Erro ao validar CPF',
            -3 => 'Error: Erro ao validar CNPJ',
            -4 => 'Error: Erro ao validar Email',
            -5 => 'Error: Erro ao validar Telefone',
            -6 => 'Error: CPF já cadastrado no banco de dados',
            -7 => 'Error: Período de gratuidade expirado. Por favor, atualize sua assinatura adquirindo um novo plano.',
            -8 => 'Error: Assinatura exiprada. Por favor, atualize sua assinatura adquirindo um novo plano.'
        ];
    }

    public static function validaCPF(string $cpf): bool
    {

        // Extrai somente os números
        $cpf = preg_replace('/[^0-9]/is', '', $cpf);

        // Verifica se foi informado todos os digitos corretamente
        if (strlen($cpf) != 11) {
            return false;
        }

        // Verifica se foi informada uma sequência de digitos repetidos. Ex: 111.111.111-11
        if (preg_match('/(\d)\1{10}/', $cpf)) {
            return false;
        }

        // Faz o calculo para validar o CPF
        for ($t = 9; $t < 11; $t++) {
            for ($d = 0, $c = 0; $c < $t; $c++) {
                $d += $cpf[$c] * (($t + 1) - $c);
            }
            $d = ((10 * $d) % 11) % 10;
            if ($cpf[$c] != $d) {
                return false;
            }
        }
        return true;
    }
}
