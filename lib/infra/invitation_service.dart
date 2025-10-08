// Crie um novo arquivo, por exemplo: invitation_service.dart

import 'dart:convert';
import 'package:application_progress/infra/api_services.dart';
import 'package:flutter/material.dart';
// Importe a sua classe de serviço API principal (ApiService)
// Ex: import 'api/api_service.dart'; 

class InvitationService {
  final ApiService _apiService = ApiService(); // Use a sua instância de ApiService

Future<Map<String, dynamic>> createInvitation({
  required int loggedInUserId,
  required int folderId,
}) async {
  try {
    // 💡 Usa o endpoint de cadastro, que agora funciona como 'criar convite'
    // O email pode ser nulo ou um placeholder se o backend aceitar.
    // Assumiremos que o email é obrigatório, usaremos um placeholder.
    final responseCadastrar = await _apiService.sendPost(
      'convite/cadastrar',
      {
        "usuario": loggedInUserId,
        "pasta": folderId,
        "email": "", // Deixe o email vazio, se o backend permitir convite sem email
      },
    );

    if (responseCadastrar['codRetorno'] == 200) {
      debugPrint('CONVITE CRIADO COM SUCESSO. ID: ${responseCadastrar['idConvite']}');
      // É CRÍTICO que a API retorne o ID do Convite criado aqui!
      return {"success": true, "message": "Convite pronto para uso.", "inviteId": responseCadastrar['idConvite']};
    } else {
      return {"success": false, "message": responseCadastrar['message'] ?? "Falha ao criar convite inicial."};
    }

  } catch (e) {
    debugPrint('Erro ao criar convite: $e');
    return {"success": false, "message": "Erro de conexão ao criar convite."};
  }
}


Future<Map<String, dynamic>> sendInvitation({
  required String email,
  required int loggedInUserId,
  required int folderId,
}) async {
  try { 
    // 1. PASSO 1: VALIDAR EXISTÊNCIA DO USUÁRIO
    final responseValida = await _apiService.sendPost(
      'usuarios/valida-existencia-usuario',
      {'email': email},
    );

    final int statusCode = responseValida['codRetorno'] ?? 500;
    
    // --- CENÁRIO 2: USUÁRIO JÁ EXISTE (codRetorno 200) ---
    if (statusCode == 200) {
      
      // 2a. AÇÃO CRÍTICA: FORÇAR A CRIAÇÃO DE UM CONVITE PENDENTE (CADASTRO)
      // O backend exige que o convite exista antes de vincular.
      final responseCadastrar = await _apiService.sendPost(
        'convite/cadastrar',
        {
          "usuario": loggedInUserId,
          "pasta": folderId,
          "email": email, // E-mail é obrigatório
        },
      );

      if (responseCadastrar['codRetorno'] != 200) {
          // Se o cadastro inicial falhar, encerra aqui
          debugPrint('Falha ao criar convite: ${responseCadastrar['message']}');
          return {"success": false, "message": responseCadastrar['message'] ?? "Falha ao criar convite antes do vínculo."};
      }
      
      debugPrint('Convite criado com sucesso para usuário existente. Prosseguindo para o vínculo...');

      // 2b. AÇÃO FINAL: VINCULAR O ÁLBUM (convite/vincular)
      // O convite deve estar pronto. Payload completo para segurança.
      final responseVincular = await _apiService.sendPost(
        'convite/vincular',
        {
          "email": email,
          "pasta": folderId,
          "usuario": loggedInUserId,
        }, 
      );
      
      if (responseVincular['codRetorno'] == 200) {
        debugPrint('VÍNCULO BEM SUCEDIDO APÓS CADASTRO PRÉVIO');
        return {"success": true, "message": "Usuário existente (${email}) vinculado com sucesso!"};
      } else {
        return {"success": false, "message": responseVincular['message'] ?? "Falha final ao vincular usuário existente."};
      }

    // --- CENÁRIO 1: USUÁRIO NÃO EXISTE (codRetorno 404) ---
    // AÇÃO: CADASTRAR/CRIAR O CONVITE PENDENTE
    } else if (statusCode == 404) {

      // O payload de cadastro (agora sabemos) precisa de todos os dados:
      final responseCadastrar = await _apiService.sendPost(
        'convite/cadastrar',
        {
          "usuario": loggedInUserId,
          "pasta": folderId,
          "email": email,
        },
      );

      if (responseCadastrar['codRetorno'] == 200) {
        debugPrint('CADASTRO/CONVITE BEM SUCEDIDO');
        return {"success": true, "message": "Convite enviado para usuário não cadastrado (${email})."};
      } else {
        return {"success": false, "message": responseCadastrar['message'] ?? "Falha ao enviar convite para novo usuário."};
      }

    } else {
      // Erro inesperado na validação
      return {"success": false, "message": responseValida['message'] ?? "Erro desconhecido na validação do e-mail."};
    }
  } catch (e) {
    debugPrint('Erro no serviço de convite: $e');
    return {"success": false, "message": "Erro de conexão ou serviço. Tente novamente."};
  }
}

  Future<List<Map<String, dynamic>>> getFolderInvites(int folderId) async {
    // 1. Chamar o endpoint da API para listar quem tem acesso ao folderId
    // 2. O resultado deve ser uma lista de mapas (ex: [{"id": 1, "email": "a@b.com", "userId": 10}, ...])
    return []; // Retornar a lista real
  }

  // FUNÇÃO DE EXCLUSÃO DE ACESSO (DESVINCULAR)

// Esta função é a principal responsável por lidar com a API.
Future<Map<String, dynamic>> deleteInviteForFolder(int folderId) async {
  try {
    // 💡 Chamada Limpa: A função na ApiService agora lida com a requisição, 
    // headers, body JSON e o tratamento de erros (lançando exceção em caso de falha).
    await _apiService.deleteInvite(folderId: folderId); 
    
    // Se a chamada acima for bem-sucedida (Status 200), o código continua aqui.
    debugPrint('Convite/Acesso para pasta $folderId excluído com sucesso.');
    return {
      "success": true,
      "message": "Acesso removido com sucesso.",
    };
  } catch (e) {
    // Em caso de falha na API (422, 500), a exceção é capturada.
    debugPrint('Erro ao remover acesso do usuário: $e');
    
    // Tentativa de extrair a mensagem de erro da exceção para exibir ao usuário.
    final errorMessage = e.toString().contains('Falha na requisição:')
        ? e.toString().split(': ').last // Pega apenas a mensagem de erro do backend
        : "Erro de conexão ao remover acesso.";
        
    return {
      "success": false,
      "message": errorMessage,
    };
  }
}

// Wrapper para manter o código da tela funcionando (o que antes era deleteFolderInvite)
// Ele agora chama a nova função principal e ignora o invitedUserId.
Future<Map<String, dynamic>> deleteFolderInvite(int folderId, int invitedUserId) async {
  // A chamada na tela (InviteScreen) agora estará correta com essa assinatura.
  return deleteInviteForFolder(folderId);
}

}