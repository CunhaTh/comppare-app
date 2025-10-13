import 'dart:convert';
import 'dart:developer';
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/models/comppare_model.dart';
import 'package:application_progress/models/response_model.dart';
import 'package:application_progress/models/tag_model.dart';
import 'package:application_progress/models/user_stats_model.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:http/http.dart' as httpClient;
import '../models/image_save_model.dart';
import '../models/models.dart'; // Para o modelo Folder
import 'package:shared_preferences/shared_preferences.dart';

/// Uma classe de serviço para interagir com a API do seu backend.
class ApiService {
  final http.Client _httpClient;

  ApiService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> getHeaders(
      {bool includeContentType = true, String? token}) {
    final String? authToken = TokenHelper().token;

    final Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }


  Future<Map<String, dynamic>> sendPost(
    String endpoint, 
    Map<String, dynamic> body,
  ) async {
    // 1. Constrói a URL completa
    final url = Uri.parse('${ApiEndpoints.baseUrl}/$endpoint'); 
    
    // 2. Cria a função de requisição (que envia o body)
    final request = () => httpClient.post(
      url, 
      headers: getHeaders()..addAll({'Content-Type': 'application/json'}), // Adiciona o Content-Type
      body: jsonEncode(body), // Converte o Map para String JSON
    );

    // 3. Usa o wrapper sendRequest para lidar com tokens, erros, etc.
    final response = await sendRequest(request); 

    // 4. Retorna a resposta processada por sendRequest
    if (response is Map<String, dynamic>) {
      return response;
    } else {
      // Caso sendRequest retorne algo inesperado ou lance um erro
      throw Exception('Formato de resposta inesperado da API.');
    }
  }

  // Excluir convite
Future<void> deleteInvite({
  required int folderId,
}) async {
  // 1. Constrói a URL completa para o endpoint de exclusão
  final url = Uri.parse(ApiEndpoints.excluiInvite);

  // 2. Define o corpo da requisição (apenas idPasta)
  final body = {
    // Garantimos que o ID seja enviado como número inteiro, conforme confirmado
    'idPasta': folderId, 
  };

  // 3. Usa o wrapper sendRequest para lidar com tokens e erros
  await sendRequest(
    () => _httpClient.post(
      url,
      // Passa o Content-Type: application/json e o Token Bearer
      headers: getHeaders(includeContentType: true), 
      body: jsonEncode(body), // Converte o Map para String JSON
    ),
    successMessage: 'Convite ou acesso geral removido com sucesso.',
    errorMessage: 'Falha ao remover o convite. Verifique se o ID está ativo no sistema.',
  );
}


/// Busca a lista de classificação do ranking.
Future<List<dynamic>> getRankingClassification() async {
  // Usamos o novo endpoint que você forneceu.
  final url = Uri.parse(ApiEndpoints.rankingClassification);
  
  // Reutilizamos sua função sendRequest para padronizar a chamada.
  final response = await sendRequest(
    () => httpClient.get(url, headers: getHeaders()),
    errorMessage: 'Falha ao buscar a classificação do ranking.',
  );
  
  // A API retorna uma lista diretamente.
  if (response is List) {
    return response;
  } else {
    // Se a resposta não for uma lista, algo está errado.
    throw ApiException('Resposta inesperada da API de ranking.');
  }
}

  /// Lista de usuários disponível apenas para rotas administrativas.
  /// Retorna a lista bruta de usuários (List ou campo 'data' quando for Map).
  Future<List<dynamic>> getAdminUsers() async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/admin/usuarios/listar');

    final response = await sendRequest(
      () => httpClient.get(url, headers: getHeaders()),
      errorMessage: 'Falha ao listar usuários (admin).',
    );

    if (response is List) {
      return response;
    }

    if (response is Map && response['data'] != null) {
      return response['data'];
    }

    throw ApiException('Resposta inesperada ao listar usuários.');
  }

  /// Exclui um usuário (admin)
  Future<void> deleteAdminUser(int id) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/admin/usuarios/excluir');

    final body = {'id': id};

    await sendRequest(
      () => httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Usuário excluído com sucesso.',
      errorMessage: 'Falha ao excluir o usuário.',
    );
  }

  /// Atualiza um usuário (admin). O mapa `updates` deve conter os campos a serem atualizados.
  Future<Map<String, dynamic>> updateAdminUser(int id, Map<String, dynamic> updates) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/admin/usuarios/atualizar');

  final body = <String, dynamic>{'id': id}..addAll(updates);

    final response = await sendRequest(
      () => httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Usuário atualizado com sucesso.',
      errorMessage: 'Falha ao atualizar o usuário.',
    );

    if (response is Map<String, dynamic>) return response;
    return {'message': 'Atualizado'};
  }

  /// Atualiza apenas o status do usuário.
  Future<dynamic> updateUserStatus(int idUsuario) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/admin/usuarios/atualizar-status');

    final body = {'idUsuario': idUsuario};

    // Log request details for debugging
    foundation.debugPrint('[updateUserStatus] POST $url');
    foundation.debugPrint('[updateUserStatus] Request body: ${jsonEncode(body)}');

    final response = await sendRequest(
      () => httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Status atualizado com sucesso.',
      errorMessage: 'Falha ao atualizar o status do usuário.',
    );

    // Log decoded response (sendRequest already logs raw response)
    foundation.debugPrint('[updateUserStatus] Decoded response: $response');
    return response;
  }

Future<void> updateRankingScore({
  required int userId, 
  required int points, 
  String? action, // 'adicionar' ou 'remover'
}) async {
  final url = Uri.parse(ApiEndpoints.updateRanking);
  
  // O corpo agora deve ser muito mais simples e incluir o campo 'acao'.
  // O backend provavelmente espera que 'pontos' seja o valor a ser adicionado/removido.
  final Map<String, String> body = {
    'usuario': userId.toString(),
    // Envia o valor do ponto. Ex: 2 pontos
    'pontos': points.toString(), 
    // Envia a chave 'acao' com o valor 'adicionar' ou 'remover'
    'acao': action!, // Usamos 'action!' pois ele é passado como obrigatório pelo _updateScoreOnBackend
  };

  await sendRequest(
    () => httpClient.post(
      url,
      headers: getHeaders(includeContentType: false),
      body: body, // O body agora usa o campo 'acao'
    ),
    errorMessage: 'Falha ao atualizar a pontuação no ranking.',
    decodeJson: false,
  );
}


// Esta função é para ATUALIZAR um subálbum existente
  Future<void> updateFolder({
    required int folderId,
    required int idUsuario,
    required String folderName, // <-- MUDANÇA: Tornou-se obrigatório
    List<int>? tagIds,
  }) async {
    final url = Uri.parse(ApiEndpoints.updateFolders);

    final body = {
      'idUsuario': idUsuario,
      'idPasta': folderId,
      'novoNome': folderName, // <-- MUDANÇA: Agora sempre envia o nome
      if (tagIds != null) 'tags': tagIds,
    };

    await sendRequest(
      () => _httpClient.post(url,
          headers: getHeaders(includeContentType: true),
          body: jsonEncode(body)),
      successMessage: 'Subálbum atualizado com sucesso.',
      errorMessage: 'Falha ao atualizar o subálbum.',
    );
  }

// Dentro da sua classe ApiService

  Future<void> saveOrUpdateComparacao(ImageModel item) async {
    final User? user = UserHelper().user;
    if (user == null || user.id == null) {
      throw ApiException('Usuário não autenticado.', statusCode: 401);
    }

    // Busca todas as tags para obter os IDs a partir dos nomes
    final List<TagModel> allTags = await getTags(user.id!);
    final Map<String, int> tagNameToIdMap = {
      for (var tag in allTags) tag.nomeTag: tag.id
    };

    // Prepara a lista de 'tags' para a API, como na sua função original
    final tagsParaAPI = item.metadata.entries
        .map((entry) {
          final tagId = tagNameToIdMap[entry.key];
          if (tagId != null) {
            return {'id_tag': tagId, 'valor': entry.value};
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    // Monta o corpo da requisição
    final body = {
      'id_usuario': user.id,
      'id_photo': item.id,
      'data_comparacao': item.date, // Usa a data diretamente do ImageModel
      'tags': tagsParaAPI,
    };

    // Envia a requisição para o endpoint correto
    // Assumindo que ApiEndpoints.salvaComparacao é a sua URL para salvar
    await sendRequest(
      () => http.post(
        Uri.parse(ApiEndpoints.salvaComparacao),
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Comparação salva com sucesso.',
      errorMessage: 'Falha ao salvar a comparação.',
    );
  }

  /// lib/infra/api_services.dart
  /// Função para carregar tags de uma pasta específica.
  Future<List<TagModel>> loadTags(int folderId) async {
    // Código da sua chamada de API aqui
    // Exemplo de resposta (substitua pela sua chamada real)
    final responseBody = {
      "codRetorno": 200,
      "message": "OK",
      "totalTags": 3,
      "data": [
        {"id": 28, "nomeTag": "NewtAgs"},
        {"id": 31, "nomeTag": "Perna"},
        {"id": 32, "nomeTag": "treino"}
      ]
    };

    if (responseBody['codRetorno'] == 200) {
      final List data = responseBody['data'] as List;
      // O mapeamento crucial para criar objetos TagModel
      return data
          .map((json) => TagModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException('Falha ao carregar tags.');
    }
  }

  Future<dynamic> sendRequest(
    Future<http.Response> Function() requestFunction, {
    String? successMessage,
    String? errorMessage,
    bool decodeJson = true,
  }) async {
    try {
      final response =
          await requestFunction().timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Adicionada verificação para corpo vazio antes de tentar decodificar
        if (decodeJson && response.body.isNotEmpty) {
          final dynamic responseBody = json.decode(response.body);
          foundation.debugPrint(
              '[sendRequest] Decoded responseBody type: ${responseBody.runtimeType}');

          if (responseBody is Map<String, dynamic>) {
            // --- INÍCIO DA CORREÇÃO ---

            // Condição 1: A resposta tem um 'codRetorno' de sucesso.
            bool hasSuccessCode = responseBody.containsKey('codRetorno') &&
                (responseBody['codRetorno'] == 200 ||
                    responseBody['codRetorno'] == 201);

            // Condição 2 (NOVA): A resposta é um sucesso simples, com 'message' mas sem 'codRetorno'.
            bool isSimpleSuccess = responseBody.containsKey('message') &&
                !responseBody.containsKey('codRetorno');

            // Se qualquer uma das condições de sucesso for verdadeira, retorne o corpo.
            if (hasSuccessCode || isSimpleSuccess) {
              return responseBody;
            }
            // Se for um status 200 mas o corpo indicar um erro (ex: codRetorno 400)
            else {
              throw ApiException(
                responseBody['message'] ??
                    errorMessage ??
                    'A API retornou um erro inesperado.',
                statusCode: response.statusCode,
                body: response.body,
              );
            }
            // --- FIM DA CORREÇÃO ---
          } else if (responseBody is List<dynamic>) {
            // Mantido o suporte para respostas em lista
            return responseBody;
          } else {
            // Se for um tipo de JSON inesperado (nem Mapa, nem Lista)
            throw ApiException(
              'Resposta inválida do servidor: formato inesperado.',
              statusCode: response.statusCode,
              body: response.body,
            );
          }
        } else {
          // Retorna um sucesso genérico se não for para decodificar ou o corpo for vazio
          return {
            'status': 'success',
            'statusCode': response.statusCode,
            'body': response.body
          };
        }
      } else {
        // O resto da sua lógica de tratamento de erro continua aqui
        String serverMessage = '';
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          serverMessage = errorBody['message'] ??
              errorBody['errors']?.toString() ??
              serverMessage;
        } catch (_) {
          serverMessage =
              response.body.isNotEmpty ? response.body : serverMessage;
        }
        throw ApiException(
          errorMessage ??
              '$serverMessage.',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Erro de conexão: ${e.message}',
          statusCode: 0, body: '');
    } on FormatException {
      throw ApiException('Resposta inválida do servidor.',
          statusCode: 0, body: '');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Erro inesperado: ${e.toString()}',
          statusCode: 0, body: '');
    }
  }
  

  // MÉTODO fetchUserStats CORRIGIDO
  Future<UserStats> fetchUserStats() async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      // CORRIGIDO: Passando a mensagem como argumento posicional
      throw ApiException('Usuário não autenticado.', statusCode: 401);
    }

    final url =
        Uri.parse('${ApiEndpoints.baseUrl}/usuarios/${user.id}/estatisticas');

    // A função de requisição é criada e passada para o seu método sendRequest
    final response =
        await sendRequest(() => httpClient.get(url, headers: getHeaders()));

    if (response is Map<String, dynamic> &&
        response['data'] != null &&
        response['data'] is Map<String, dynamic>) {
      return UserStats.fromJson(response['data']);
    } else {
      // CORRIGIDO: Passando a mensagem como argumento posicional
      throw ApiException('Resposta de estatísticas inválida da API.');
    }
  }

  // lib/infra/api_services.dart
  // CORREÇÃO: Método revisado para usar sendRequest e incluir o ID do usuário.
  /// Função para excluir uma tag existente pelo seu ID.
  /// O endpoint para esta requisição deve ser definido em `ApiEndpoints`
  /// como `excluiTags`. Certifique-se de que o backend espera o `idTag` no corpo
  /// da requisição DELETE.
  Future<Future> deleteTag(int idTag, String nomeTag) async {
    // Acessa o ID do usuário do TokenHelper
    final int? idUsuario = TokenHelper().userId;

    // Verifica se o ID do usuário é válido antes de prosseguir
    if (idUsuario == 0) {
      throw ApiException(
          'ID do usuário não disponível. Por favor, faça login novamente.',
          statusCode: 401);
    }

    final url = Uri.parse(ApiEndpoints.excluiTags);

    // O token será verificado automaticamente em getHeaders( e sendRequest.
    // Inclui agora o idUsuario no corpo da requisição
    final body = {
      'idTag': idTag,
      'usuario': idUsuario, // Adicionado o ID do usuário
    };

    foundation.debugPrint(
        'Requisição para excluir tag em: $url, ID: $idTag, Usuário: $idUsuario');

    return sendRequest(
      // Usando o método DELETE e enviando o corpo com o ID da tag e do usuário.
      () => _httpClient.delete(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Tag excluída com sucesso.',
      errorMessage: 'Falha ao excluir tag.',
    );
  }

// DENTRO DO SEU ARQUIVO api_services.dart

Future<Map<String, dynamic>> authenticateUser(
  String cpf,
  String senha, {
  String? token, // Parâmetro opcional para usar token existente
}) async {
  final url = Uri.parse(ApiEndpoints.authenticateUser);

  Map<String, String> headers = getHeaders(includeContentType: true);
  final body = <String, dynamic>{};
  bool isRefresh = false;

  if (token != null && token.isNotEmpty) {
    // Modo refresh: usa o token nos cabeçalhos
    headers['Authorization'] = 'Bearer $token';
    foundation.debugPrint('Usando token existente para refresh.');
    isRefresh = true;
  } else {
    // Modo login inicial: envia CPF e senha
    body['cpf'] = cpf;
    body['senha'] = senha;
    foundation.debugPrint('Autenticando com CPF e senha.');
  }

  // Com a análise final dos logs, sabemos que o backend SÓ aceita POST.
  // Mantemos o POST para ambos os casos. O erro anterior era no backend.
  // Se o erro 422 voltar no refresh, a correção DEVE ser no backend.
  final responseBody = await sendRequest(
    () => _httpClient.post(
      url,
      headers: headers,
      body: body.isNotEmpty ? jsonEncode(body) : null,
    ),
    successMessage: 'Autenticação bem-sucedida.',
    errorMessage: 'Falha na autenticação. Verifique suas credenciais.',
  );

  if (responseBody.containsKey('token') &&
      responseBody['token'] is String &&
      responseBody.containsKey('dados') &&
      responseBody['dados'] is Map<String, dynamic>) {
    final String newToken = responseBody['token'] as String;
    
    // Pega o objeto "dados" inteiro
    final Map<String, dynamic> userData =
        responseBody['dados'] as Map<String, dynamic>;

    final User loggedInUser = User(
      id: userData['id'] as int?,
      nome: '${userData['primeiroNome']} ${userData['sobrenome']}',
      cpf: userData['cpf'] as String?,
      telefone: userData['telefone'] as String?,
      idPlano: userData['idPlano'] as int?,
      email: userData['email'] as String?,
      token: newToken,
    );

    // --- CORREÇÃO PRINCIPAL APLICADA AQUI ---
    // Agora procuramos a lista de pastas DENTRO do objeto 'userData'
    if (userData.containsKey('pastas') && userData['pastas'] is List) {
      final List<dynamic> pastasJson = userData['pastas'] as List<dynamic>;
      loggedInUser.pastas = pastasJson
          .map((item) => Folder.fromMap(item as Map<String, dynamic>))
          .toList();
      foundation.debugPrint(
          'ApiService: Pastas encontradas DENTRO DE "DADOS": ${loggedInUser.pastas?.length}');
    } else {
      loggedInUser.pastas = [];
      foundation.debugPrint(
          'ApiService: Nenhuma pasta encontrada no objeto "dados".');
    }
    // --- FIM DA CORREÇÃO ---

    await TokenHelper().saveToken(newToken);
    await TokenHelper().saveUserId(loggedInUser.id!);
    await UserHelper().setUser(loggedInUser);

    return responseBody;
  } else {
    throw ApiException(
      'Resposta de autenticação inválida: Token ou dados do usuário ausentes.',
      statusCode: responseBody['statusCode'] as int? ?? 0,
      body: json.encode(responseBody),
    );
  }
}

// Nova função para autenticar administradores usando o endpoint /usuarios/login-admin
Future<Map<String, dynamic>> authenticateAdmin(
  String cpf,
  String senha, {
  String? token,
}) async {
  final url = Uri.parse(ApiEndpoints.authenticateAdmin);

  Map<String, String> headers = getHeaders(includeContentType: true);
  final body = <String, dynamic>{};

  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
    foundation.debugPrint('authenticateAdmin: usando token existente para refresh.');
  } else {
    body['cpf'] = cpf;
    body['senha'] = senha;
    foundation.debugPrint('authenticateAdmin: autenticando com CPF e senha.');
  }

  final responseBody = await sendRequest(
    () => _httpClient.post(
      url,
      headers: headers,
      body: body.isNotEmpty ? jsonEncode(body) : null,
    ),
    successMessage: 'Autenticação admin bem-sucedida.',
  );

  // A API de admin pode retornar apenas id/nome (dentro de 'dados' ou no topo) e
  // opcionalmente um token. Não altere o comportamento de authenticateUser.
  Map<String, dynamic>? userData;
  if (responseBody is Map<String, dynamic>) {
    if (responseBody.containsKey('dados') && responseBody['dados'] is Map<String, dynamic>) {
      userData = responseBody['dados'] as Map<String, dynamic>;
    } else if (responseBody.containsKey('id')) {
      userData = responseBody;
    }
  }

  if (userData == null) {
    throw ApiException(
      'Resposta de autenticação inválida (admin): dados do usuário ausentes.',
      statusCode: responseBody is Map<String, dynamic> ? responseBody['statusCode'] as int? ?? 0 : 0,
      body: json.encode(responseBody),
    );
  }

  final int? id = userData['id'] is String ? int.tryParse(userData['id']) : userData['id'] as int?;
  final String? nome = (userData['nome'] as String?) ?? (userData['primeiroNome'] != null ? '${userData['primeiroNome']} ${userData['sobrenome'] ?? ''}'.trim() : null);


  final User loggedInUser = User(
    id: id,
    nome: nome,
    cpf: null,
    senha: null,
    telefone: null,
    idPlano: null,
    email: null,
    token: null,
  );

  // Save token/user id only if present. UserHelper.setUser requires an id to persist.
 
  if (id != null) {
    await TokenHelper().saveUserId(id);
    await UserHelper().setUser(loggedInUser);
  }

  return responseBody as Map<String, dynamic>;
}

  // lib/infra/api_services.dart
  Future<Future> getFolderById(int folderId) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/folders/$folderId');
    return sendRequest(
      () => _httpClient.get(url, headers: getHeaders()),
      successMessage: 'Pasta carregada com sucesso.',
      errorMessage: 'Falha ao carregar pasta.',
    );
  }

  // FUNÇÃO CORRIGIDA - Agora retorna Future<Map<String, dynamic>>
  Future<Map<String, dynamic>> createFolder({
    int? parentFolderId,
    required int idUsuario,
    required String folderName,
    List<String>? tags,
  }) async {
    final url = Uri.parse(ApiEndpoints.createFolder);
    final body = {
      'idUsuario': idUsuario,
      'nomePasta': folderName,
      if (parentFolderId != null) 'parentFolderId': parentFolderId,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    };

    // AWAIT foi adicionado aqui para esperar o resultado antes de retornar
    final response = await sendRequest(
      () => _httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Pasta/subpasta criada com sucesso.',
      errorMessage: 'Você atingiu o limite de albuns criados.',
    );
    return response;
  }

  // NOVA FUNÇÃO - Usa sua lógica de autenticação para atualizar os dados
 /* Future<void> refreshUserData() async {
    final token = TokenHelper().token;
    if (token == null || token.isEmpty) {
      throw ApiException('Nenhum token disponível para atualização.',
          statusCode: 401);
    }

    // Chama sua função de autenticação em modo "refresh", que busca os dados do usuário
    // e já atualiza o TokenHelper e UserHelper internamente.
    await authenticateUser('', '', token: token);
  }*/

  Future<void> deleteFolder(int idUsuario, int idPasta) async {
    final url = Uri.parse(ApiEndpoints.deleteFolder);
    foundation
        .debugPrint('Requisição para excluir pasta em: $url, ID: $idPasta');

   await sendRequest(
      () => _httpClient.delete(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode({
          'idUsuario': idUsuario,
          'idPasta': idPasta,
        }),
      ),
      successMessage: 'Pasta excluída com sucesso.',
      errorMessage: 'Falha ao excluir pasta.',
    );
     // MUDANÇA 3: Remove o álbum do cache local APÓS o sucesso da API
  // Isso garante que a próxima leitura de dados estará correta.
  UserHelper().user?.pastas?.removeWhere((pasta) => pasta.id == idPasta);
  }

  /// lib/infra/api_services.dart
  /// **CORREÇÃO:** Método revisado para usar sendRequest.
  /// Função para excluir uma tag existente pelo seu ID.
  /// O endpoint para esta requisição deve ser definido em `ApiEndpoints`
  /// como `excluiTags`. Certifique-se de que o backend espera o `idTag` no corpo
  /// da requisição DELETE.
  Future<Future> _deleteTag(int idTag) async {
    final url = Uri.parse(ApiEndpoints.excluiTags);

    // O token será verificado automaticamente em getHeaders( e sendRequest.
    final body = {'idTag': idTag};

    foundation.debugPrint('Requisição para excluir tag em: $url, ID: $idTag');

    return sendRequest(
      // Usando o método DELETE e enviando o corpo com o ID da tag.
      () => _httpClient.delete(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Tag excluída com sucesso.',
      errorMessage: 'Falha ao excluir tag.',
    );
  }

  Future<Future> deleteImage(int idUsuario, int idImagem) async {
    final url = Uri.parse(ApiEndpoints.deleteImage);
    foundation
        .debugPrint('Requisição para excluir imagem em: $url, ID: $idImagem');

    return sendRequest(
      () => _httpClient.delete(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode({
          'idUsuario': idUsuario,
          'idImagem': idImagem,
        }),
      ),
      successMessage: 'Imagem excluída com sucesso.',
      errorMessage: 'Falha ao excluir imagem.',
    );
  }

  
Future<void> refreshUserData() async {
  final token = TokenHelper().token;
  final userId = TokenHelper().userId;

  if (token == null || userId == null) {
    throw ApiException('Usuário não autenticado para refresh.', statusCode: 401);
  }

  // A URL CORRETA que você encontrou!
  final url = Uri.parse('${ApiEndpoints.baseUrl}/usuarios/pastas/$userId');
  
  foundation.debugPrint('refreshUserData: Buscando todas as pastas em $url');

  final responseBody = await sendRequest(
    () => _httpClient.get(url, headers: getHeaders()),
    errorMessage: 'Falha ao buscar a lista de pastas do usuário.',
  );

  // --- INÍCIO DA CORREÇÃO FINAL ---

  // 1. Verificamos se a resposta é um Objeto (Map) e se contém a chave "pastas"
  if (responseBody is Map<String, dynamic> && responseBody.containsKey('pastas')) {
    
    // 2. Pegamos a lista de DENTRO da chave "pastas"
    final List<dynamic> pastasJson = responseBody['pastas'] as List<dynamic>;

    final List<Folder> folders = pastasJson
        .map((item) => Folder.fromMap(item as Map<String, dynamic>))
        .toList();

    // 3. O resto da lógica para atualizar o cache local funciona perfeitamente
    final user = UserHelper().user;
    if (user != null) {
      user.pastas = folders;
      await UserHelper().setUser(user);
      foundation.debugPrint('UserHelper atualizado com ${folders.length} pastas da API.');
    }
  } else {
    // Se a resposta não for um objeto com a chave "pastas", algo está errado.
    foundation.debugPrint('Resposta inesperada da API. Esperava um Objeto com a chave "pastas", mas recebi: $responseBody');
    throw ApiException('A resposta da API para listar pastas não era o formato esperado.');
  }
  // --- FIM DA CORREÇÃO FINAL ---
}
  /// Função para listar TODAS as pastas principais do usuário logado.
  /// Este método agora obtém as pastas do UserHelper, que foram salvas durante o login.
  Future<List<Folder>> getAllFoldersForUser() async {
    final User? user = UserHelper().user;

    if (user == null || user.pastas == null) {
      throw ApiException(
          'Dados do usuário ou pastas não disponíveis no cache local. Por favor, faça login novamente.',
          statusCode: 401,
          body: '');
    }
    return user.pastas!;
  }

  Future<List<Folder>> fetchSubfolders(int parentFolderId) async {
    final url = Uri.parse('${ApiEndpoints.recoverFolder}?idPasta=$parentFolderId');

    final response = await sendRequest(
      () => _httpClient.get(url, headers: getHeaders()),
      errorMessage: 'Falha ao carregar subpastas.',
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> subfoldersJson =
        data['subpastas'] as List<dynamic>? ?? [];

    // A CORREÇÃO ESTÁ AQUI:
    // Agora passamos o mapa 'subfolder' inteiro diretamente para o Folder.fromMap.
    // O fromMap que já corrigimos saberá como processar todos os campos, incluindo as 'tags'.
    return subfoldersJson.map((subfolder) {
      // Adicionamos o idPastaPai manualmente, pois ele não vem na resposta da API
      (subfolder as Map<String, dynamic>)['idPastaPai'] = parentFolderId;
      return Folder.fromMap(subfolder);
    }).toList();
  }

  /// Função para fazer upload de imagens para uma pasta específica.
  Future<List<ImageModel>> uploadImages({
    required List<PickedFileItem> images,
    required int folderId,
  }) async {
    final url = Uri.parse(ApiEndpoints.uploadImages);
    final String? authToken = TokenHelper().token;
    // O ID do usuário não é mais enviado como campo, assumimos que o backend o obtém do token.
    // final int userId = TokenHelper().userId;

    if (authToken == null || authToken.isEmpty) {
      // Removido userId == 0 da condição
      throw ApiException('Usuário não autenticado para upload de imagens.',
          statusCode: 401, body: '');
    }

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $authToken';

    // ⭐ Removendo debugPrints redundantes e o campo idUsuario
    // foundation.debugPrint('Upload: idUsuario = $userId');
    foundation.debugPrint('Upload: idPasta = $folderId');

    // request.fields['idUsuario'] = userId.toString(); // ⭐ REMOVIDO: idUsuario não é mais enviado como campo
    request.fields['idPasta'] = folderId.toString(); // ID da pasta para upload

    for (var i = 0; i < images.length; i++) {
      final fileItem = images[i];
      if (fileItem.bytes != null) {
        foundation.debugPrint(
            'Upload: Adicionando arquivo ${fileItem.platformFile.name} (tamanho: ${fileItem.bytes!.length} bytes) ao campo image[]');
        request.files.add(
          http.MultipartFile.fromBytes(
            'image[]', // ⭐ CORREÇÃO AQUI: Nome do campo mudado para 'image[]'
            fileItem.bytes!,
            filename: fileItem.platformFile.name,
          ),
        );
      } else {
        foundation.debugPrint(
            'Upload: Aviso - Arquivo ${fileItem.platformFile.name} (índice $i) possui bytes nulos ou nome nulo. Ignorando.');
      }
    }

    foundation.debugPrint(
        'Enviando ${request.files.length} imagens para a pasta $folderId...');

    final response =
        await _httpClient.send(request).timeout(const Duration(seconds: 60));
    final responseBody = await response.stream.bytesToString();

    foundation.debugPrint(
        'Upload Response Status: ${response.statusCode}, Body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonResponse =
          json.decode(responseBody) as Map<String, dynamic>;
      if (jsonResponse.containsKey('codRetorno') &&
          jsonResponse['codRetorno'] == 200) {
        if (jsonResponse.containsKey('image_paths') &&
            jsonResponse['image_paths'] is List) {
          // ⭐ CORREÇÃO AQUI: Espera 'image_paths'
          // A API retorna apenas os caminhos das imagens, não o objeto MyImage completo.
          // Precisamos adaptar a criação de MyImage.
          List<ImageModel> uploadedImages = [];
          for (var path in jsonResponse['image_paths']) {
            // Assumimos que o backend não retorna o ID da imagem aqui,
            // então usaremos um ID temporário ou 0, e um takenAt padrão.
            // Se o backend retornar o ID e takenAt, você precisará ajustar.
            uploadedImages.add(ImageModel(
              id: 0, // ID temporário, pois a API não o retorna neste ponto
              url: path as String,
              //takenAt: DateTime.now().toIso8601String(),
              // Data atual como fallback
            ));
          }
          return uploadedImages;
        }
        return [];
      } else {
        throw ApiException(
          jsonResponse['message'] ?? 'Erro desconhecido no upload.',
          statusCode: response.statusCode,
          body: responseBody,
        );
      }
    } else {
      String serverMessage = 'Falha no upload da imagem.';
      try {
        final errorBody = json.decode(responseBody) as Map<String, dynamic>;
        serverMessage = errorBody['message'] ??
            errorBody['errors']?.toString() ??
            serverMessage;
      } catch (_) {
        serverMessage = responseBody.isNotEmpty ? responseBody : serverMessage;
      }
      throw ApiException(
        serverMessage,
        statusCode: response.statusCode,
        body: responseBody,
      );
    }
  }

// Esta função é para CRIAR um novo subálbum
  Future<Map<String, dynamic>> createSubFolder({
    required int parentFolderId,
    required int idUsuario,
    required String folderName, // Nome do novo subálbum
    required String parentFolderName, // Nome da pasta PAI
    List<String>? tags,
  }) async {
    final url = Uri.parse(ApiEndpoints.createFolder);

    // Lógica corrigida e simplificada para criar o nome no formato "PastaPai/Subpasta"
    final String nomePasta = '$parentFolderName/$folderName'.trim();

    final body = {
      'idUsuario': idUsuario,
      'nomePasta': nomePasta,
      // O backend já identifica a pasta pai pelo formato do nome,
      // mas enviar o ID é uma boa prática se a API o suportar.
      'parentFolderId': parentFolderId,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    };

    final response = await sendRequest(
      () => _httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Subálbum criado com sucesso.',
      errorMessage: 'Falha ao criar subálbum, Você atingiu o limite de subálbuns criados.',
    );
    return response as Map<String, dynamic>;
  }

Future<String?> refreshTokenIfNeeded() async {
  final tokenHelper = TokenHelper();
  final token = tokenHelper.token;
  if (token != null) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        // --- INÍCIO DA CORREÇÃO ---
        // 1. Decodifica o Base64Url para uma lista de bytes (List<int>)
        final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
        // 2. Converte os bytes UTF-8 para uma String legível
        final decodedPayload = utf8.decode(payloadBytes);
        // 3. Agora sim, decodifica a String JSON para um Map
        final payload = json.decode(decodedPayload);
        // --- FIM DA CORREÇÃO ---

        final expiry = payload['exp'] as int? ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Renova se faltar 5 minutos ou menos
        if (expiry < now + 300) { 
          // Tenta renovar o token usando o token atual
          final response = await authenticateUser('', '', token: token);
          return response['token'] as String?; // Retorna o novo token
        }
        return token; // Retorna o token atual se não estiver perto de expirar
      }
    } catch (e) {
      foundation
          .debugPrint('[_refreshTokenIfNeeded] Erro ao verificar token: $e');
    }
  }
  return null; // Retorna null se não houver token ou se ocorrer um erro
}



  Future<Map<String, dynamic>?> getParentFolderDetails(
      int parentFolderId) async {
    final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/pasta/recuperar?idPasta=$parentFolderId');
    try {
      final response = await sendRequest(
        () => _httpClient.get(url, headers: getHeaders()),
        successMessage: 'Detalhes da pasta pai carregados.',
        errorMessage: 'Falha ao carregar detalhes da pasta pai.',
      );
      foundation
          .debugPrint('[getParentFolderDetails] Resposta da API: $response');
      return response;
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        foundation.debugPrint(
            '[getParentFolderDetails] Pasta pai não encontrada para ID: $parentFolderId');
        return null;
      }
      rethrow;
    }
  }

// lib/infra/api_services.dart
  Future<Future> fetchFolderDetails(int folderId) async {
    final url =
        Uri.parse('${ApiEndpoints.baseUrl}/pasta/recuperar?idPasta=$folderId');
    return sendRequest(
      () => _httpClient.get(
        url,
        headers: getHeaders(includeContentType: true),
      ),
      errorMessage: 'Falha ao recuperar detalhes da pasta.',
    );
  }

  Future<Future> createPaymentWithCard(PaymentModel payment) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/vendas/criar-assinatura');
    log("URL DA ASSINATURA: $url || BODY ENVIADO: ${jsonEncode(payment.toMap())}");
    log("CABEÇALHOS: ${getHeaders(includeContentType: true)}");
    return sendRequest(
      () => _httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(payment.toMap()),
      ),
      successMessage: 'Assinatura criada com sucesso.',
      errorMessage: 'Falha ao criar assinatura.',
    );
  }

  Future<PaymentPixReturnModel> createPaymentWithPix({
    required int userId,
    required int planId,
  }) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/pix/enviar');
    log("URL DA ASSINATURA PIX: $url || BODY ENVIADO: ${jsonEncode({
          'usuario': userId,
          'plano': planId,
        })}");

    final response = await sendRequest(
      () => _httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode({
          'usuario': userId,
          'plano': planId,
        }),
      ),
      successMessage: 'Pix enviado com sucesso.',
      errorMessage: 'Falha ao enviar pix.',
    );

    return PaymentPixReturnModel.fromMap(response);
  }

  /// Função para salvar tags no servidor.
  Future<Map<String, dynamic>> saveTags({
    // DEPOIS: Apenas um Future
    required String nomeTag,
    required int usuario,
  }) async {
    final url = Uri.parse(ApiEndpoints.cadastraTags);
    foundation.debugPrint(
        '[_saveTags] Requisição para salvar tags em: $url, nomeTag: $nomeTag, usuario: $usuario');

    final body = {
      'nomeTag': nomeTag,
      'usuario': usuario,
    };

    // Adicionamos 'await' para esperar a resposta e 'return' para devolvê-la.
    final response = await sendRequest(
      () => _httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Tags salvas com sucesso.',
      errorMessage: 'Falha ao salvar tags.',
    );
    return response as Map<String, dynamic>;
  }

  Future<List<TagModel>> getTags(int usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'user_${usuario}_tags_cache';

    try {
      // 1. Tenta buscar da API primeiro para ter os dados mais recentes
      final url = Uri.parse(ApiEndpoints.listarTags);
      final body = {'usuario': usuario};

      final responseBody = await sendRequest(
        () => _httpClient.post(
          url,
          headers: getHeaders(includeContentType: true),
          body: jsonEncode(body),
        ),
      );

      if (responseBody.containsKey('data') && responseBody['data'] is List) {
        final List<dynamic> tagsJson = responseBody['data'] as List<dynamic>;
        final tags = tagsJson
            .map((json) => TagModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // 2. Se a busca na API foi bem-sucedida, SALVA no cache
        //    Convertemos os objetos TagModel para uma lista de Mapas e depois para String
        final List<Map<String, dynamic>> tagsToCache =
            tags.map((t) => t.toMap()).toList();
        await prefs.setString(cacheKey, jsonEncode(tagsToCache));

        debugPrint('Tags carregadas da API e salvas no cache.');
        return tags;
      }

      return [];
    } catch (e) {
      debugPrint(
          'Falha ao buscar tags da API: $e. Tentando carregar do cache...');

      // 3. Se a API falhar, TENTA carregar do cache
      final cachedTagsString = prefs.getString(cacheKey);
      if (cachedTagsString != null) {
        final List<dynamic> tagsJson = jsonDecode(cachedTagsString);
        final tags = tagsJson
            .map((json) => TagModel.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('Tags carregadas com sucesso do cache.');
        return tags;
      }

      // 4. Se a API e o cache falharem, lança o erro ou retorna uma lista vazia
      debugPrint('Cache de tags também está vazio.');
      throw ApiException('Não foi possível carregar as categorias.');
    }
  }

  Future<ComparacaoModel> getComparacaoSave(int idPhoto) async {
    final User? user = UserHelper().user;
    if (user == null || user.id == null || user.token == null) {
      throw ApiException('Usuário não autenticado.', statusCode: 401);
    }

    final url = Uri.parse(ApiEndpoints.getComparacao(idPhoto));
    foundation.debugPrint('Requesting URL: $url');
    final responseBody = await sendRequest(
      () => _httpClient.get(
        url,
        headers: {
          ...getHeaders(includeContentType: true),
          'Authorization': 'Bearer ${user.token}',
        },
      ),
      successMessage: 'Comparação carregada com sucesso.',
      errorMessage: 'Falha ao carregar a comparação.',
    );
    foundation.debugPrint('Raw responseBody: $responseBody');

    if (responseBody is List && responseBody.isNotEmpty) {
      final Map<String, dynamic> comparacaoJson =
          responseBody.first as Map<String, dynamic>;
      foundation.debugPrint('Comparação recuperada: $comparacaoJson');
      return ComparacaoModel.fromJson(comparacaoJson);
    } else if (responseBody is Map<String, dynamic>) {
      if (responseBody.containsKey('data') && responseBody['data'] is Map) {
        final Map<String, dynamic> comparacaoJson =
            responseBody['data'] as Map<String, dynamic>;
        foundation.debugPrint('Comparação recuperada: $comparacaoJson');
        return ComparacaoModel.fromJson(comparacaoJson);
      }
    }
    foundation.debugPrint(
        'Nenhuma comparação encontrada para o idPhoto: $idPhoto. ResponseBody: $responseBody');
    throw ApiException('Nenhuma comparação encontrada.', statusCode: 404);
  }

  Future<PlanModel> getPlanById(int planId) async {
    try {
      final url = Uri.parse('${ApiEndpoints.getPlanById}/$planId');
      log("URL DE BUSCA DE PLANO POR ID: $url");

      final response = await sendRequest(
        () => _httpClient.get(
          url,
          headers: getHeaders(includeContentType: true),
        ),
        successMessage: 'Plano recuperado com sucesso.',
        errorMessage: 'Falha ao recuperar plano.',
      );

      log("RESPOSTA DA API - GET PLAN BY ID: ${jsonEncode(response)}");

      if (response['codRetorno'] == 200) {
        return PlanModel.fromJson(response['data']);
      } else {
        throw ApiException(response['message'],
            statusCode: response['codRetorno']);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> cancelPlan(int idUser) async {
    try {
      final url = Uri.parse(ApiEndpoints.cancelPlan);
      log("URL DE BUSCA DE PLANO POR ID: $url");

      final response = await sendRequest(
        () => _httpClient.post(
          url,
          headers: getHeaders(includeContentType: true),
          body: jsonEncode({'usuario': idUser}),
        ),
        successMessage: 'Plano recuperado com sucesso.',
        errorMessage: 'Falha ao recuperar plano.',
      );

      log("RESPOSTA DA API - CANCELAR PLANO: ${jsonEncode(response)}");

      if (response['codRetorno'] == 200) {
        return ResponseModel.fromMap(response);
      } else {
        throw ApiException(response['message'],
            statusCode: response['codRetorno']);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ResponseModel> saveImageData(Map<String, dynamic> body) async {
    try {
      final url = Uri.parse(ApiEndpoints.salvaComparacao);
      log("URL DE SALVAR DADOS DA IMAGEM: $url");
      log("BODY ENVIADO com jsonEncode: ${jsonEncode(body)}");

      final response = await sendRequest(
        () => _httpClient.post(
          url,
          headers: getHeaders(includeContentType: true),
          body: jsonEncode(body),
        ),
        successMessage: 'Dados da imagem salvos com sucesso.',
        errorMessage: 'Falha ao salvar dados da imagem.',
      );

      log("RESPOSTA DA API - SALVAR DADOS DA IMAGEM: ${jsonEncode(response)}");

      if (response['codRetorno'] == 200) {
        return ResponseModel.fromMap(response);
      } else {
        // throw ApiException(response['message'],
        //     statusCode: response['codRetorno']);
        return ResponseModel.empty();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lista todos os planos disponíveis (admin)
  Future<List<dynamic>> getPlans() async {
    final url = Uri.parse(ApiEndpoints.getPlans);

    final response = await sendRequest(
      () => _httpClient.get(url, headers: getHeaders()),
      errorMessage: 'Falha ao listar planos.',
    );

    if (response is List) return response;
    if (response is Map && response['data'] != null) return response['data'];
    throw ApiException('Resposta inesperada ao listar planos.');
  }

  /// Atualiza dados do usuário (endpoint público): /usuarios/atualizar-dados
  Future<dynamic> updateUserData(Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/admin/usuarios/atualizar-dados');
    foundation.debugPrint('[ApiService] updateUserData POST $url');
    foundation.debugPrint('[ApiService] updateUserData body: ${jsonEncode(body)}');

    final response = await sendRequest(
      () => _httpClient.post(
        url,
        headers: getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Dados do usuário atualizados.',
      errorMessage: 'Falha ao atualizar dados do usuário.',
    );

    foundation.debugPrint('[ApiService] updateUserData response: $response');
    return response;
  }
}
