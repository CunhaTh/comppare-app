// lib/infra/api_services.dart

import 'dart:convert';
import 'package:application_progress/infra/api_exception.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:http/http.dart' as http;
import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/models/image_model.dart'; // Mantido para ImageModel se usado em Folder ou outros lugares
import 'package:application_progress/infra/user_helper.dart'; // Importar UserHelper

/// Uma classe de serviço para interagir com a API do seu backend.
class ApiService {
  final http.Client _httpClient;

  ApiService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Map<String, String> _getHeaders({bool includeContentType = true}) {
    final String? authToken = TokenHelper().token;
    foundation.debugPrint('ApiService: Token sendo acessado em _getHeaders: $authToken');
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    } else {
      foundation.debugPrint('Aviso: Token de autenticação não disponível no TokenHelper.');
    }
    return headers;
  }

  Future<Map<String, dynamic>> _sendRequest(
    Future<http.Response> Function() requestFunction, {
    String? successMessage,
    String? errorMessage,
    bool decodeJson = true,
  }) async {
    try {
      final response = await requestFunction().timeout(const Duration(seconds: 20));

      foundation.debugPrint('Response Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decodeJson) {
          final Map<String, dynamic> responseBody = json.decode(response.body) as Map<String, dynamic>;
          if (responseBody.containsKey('codRetorno') && responseBody['codRetorno'] == 200) {
            return responseBody;
          } else {
            throw ApiException(
              responseBody['message'] ?? (successMessage ?? 'Erro desconhecido na API.'),
              statusCode: response.statusCode,
              body: response.body,
            );
          }
        } else {
          return {'status': 'success', 'statusCode': response.statusCode, 'body': response.body};
        }
      } else if (response.statusCode == 401) {
        throw ApiException(
          'Não autorizado: Token inválido ou expirado.',
          statusCode: 401,
          body: response.body,
        );
      } else {
        String serverMessage = 'Falha na requisição.';
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          serverMessage = errorBody['message'] ?? errorBody['errors']?.toString() ?? serverMessage;
        } catch (_) {
          serverMessage = response.body.isNotEmpty ? response.body : serverMessage;
        }

        throw ApiException(
          errorMessage ?? 'Falha na requisição: $serverMessage (Status ${response.statusCode}).',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Erro de conexão: ${e.message}', statusCode: 0, body: '');
    } on FormatException {
      throw ApiException('Resposta inválida do servidor.', statusCode: 0, body: '');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Erro inesperado: ${e.toString()}', statusCode: 0, body: '');
    }
  }

  /// Função para autenticar o usuário.
  /// Salva o token e o ID do usuário no TokenHelper e o objeto User completo no UserHelper.
  Future<Map<String, dynamic>> authenticateUser(String cpf, String senha) async {
    final url = Uri.parse(ApiEndpoints.authenticateUser);
    foundation.debugPrint('Tentando autenticar usuário: $cpf');

    final responseBody = await _sendRequest(
      () => _httpClient.post(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode({
          'cpf': cpf,
          'senha': senha,
        }),
      ),
      successMessage: 'Autenticação bem-sucedida.',
      errorMessage: 'Falha na autenticação. Verifique suas credenciais.',
    );

    if (responseBody.containsKey('token') && responseBody['token'] is String &&
        responseBody.containsKey('dados') && responseBody['dados'] is Map<String, dynamic>) {

      final String token = responseBody['token'] as String;
      final Map<String, dynamic> userData = responseBody['dados'] as Map<String, dynamic>;

      // Cria o objeto User com os dados de autenticação
      final User loggedInUser = User(
        id: userData['id'] as int?,
        nome: '${userData['primeiroNome']} ${userData['sobrenome']}',
        cpf: userData['cpf'] as String?,
        telefone: userData['telefone'] as String?,
        idPlano: userData['idPlano'] as int?,
        email: userData['email'] as String?,
        token: token, // Atribui o token ao objeto User
      );

      // Extrai e anexa a lista de pastas ao objeto User
      if (responseBody.containsKey('pastas') && responseBody['pastas'] is List) {
        final List<dynamic> pastasJson = responseBody['pastas'] as List<dynamic>;
        loggedInUser.pastas = pastasJson.map((item) => Folder.fromMap(item as Map<String, dynamic>)).toList();
        foundation.debugPrint('ApiService: Pastas encontradas na resposta de autenticação: ${loggedInUser.pastas?.length}');
      } else {
        loggedInUser.pastas = [];
        foundation.debugPrint('ApiService: Nenhuma pasta encontrada na resposta de autenticação.');
      }

      // Salva o token e o ID do usuário no TokenHelper
      await TokenHelper().saveToken(token);
      await TokenHelper().saveUserId(loggedInUser.id!);

      // Salva o objeto User completo (com pastas) no UserHelper
      await UserHelper().setUser(loggedInUser); // <--- CRUCIAL: Salva o User completo

      return responseBody;
    } else {
      throw ApiException(
        'Resposta de autenticação inválida: Token ou dados do usuário ausentes.',
        statusCode: responseBody['statusCode'] as int? ?? 0,
        body: json.encode(responseBody),
      );
    }
  }

  Future<Map<String, dynamic>> createFolder(int idUsuario, String folderName, {int? parentFolderId}) async {
    final url = Uri.parse(ApiEndpoints.createFolder);
    foundation.debugPrint('Requisição para criar pasta/subpasta em: $url com nome: $folderName');

    return _sendRequest(
      () => _httpClient.post(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode({
          'idUsuario': idUsuario,
          'nomePasta': folderName,
          if (parentFolderId != null) 'parentFolderId': parentFolderId,
        }),
      ),
      successMessage: 'Pasta/subpasta criada com sucesso.',
      errorMessage: 'Falha ao criar pasta/subpasta.',
    );
  }

  Future<Map<String, dynamic>> deleteFolder(int idUsuario, int idPasta) async {
    final url = Uri.parse(ApiEndpoints.deleteFolder);
    foundation.debugPrint('Requisição para excluir pasta em: $url, ID: $idPasta');

    return _sendRequest(
      () => _httpClient.delete(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode({
          'idUsuario': idUsuario,
          'idPasta': idPasta,
        }),
      ),
      successMessage: 'Pasta excluída com sucesso.',
      errorMessage: 'Falha ao excluir pasta.',
    );
  }

  Future<Map<String, dynamic>> deleteImage(int idUsuario, int idImagem) async {
    final url = Uri.parse(ApiEndpoints.deleteImage);
    foundation.debugPrint('Requisição para excluir imagem em: $url, ID: $idImagem');

    return _sendRequest(
      () => _httpClient.delete(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode({
          'idUsuario': idUsuario,
          'idImagem': idImagem,
        }),
      ),
      successMessage: 'Imagem excluída com sucesso.',
      errorMessage: 'Falha ao excluir imagem.',
    );
  }

  /// Função para listar TODAS as pastas principais do usuário logado.
  /// Este método agora irá buscar as pastas do UserHelper, que foram salvas durante o login.
  /// Não faz mais uma requisição separada à API para listar todas as pastas.
  Future<List<Folder>> getAllFoldersForUser() async {
    final String? token = TokenHelper().token;
    final int currentUserId = TokenHelper().userId;
    final User? user = UserHelper().user; // Obtém o usuário do UserHelper

    foundation.debugPrint('ApiService.getAllFoldersForUser: Token do TokenHelper: $token, User ID: $currentUserId, UserHelper.user: ${user?.nome}');

    if (token == null || token.isEmpty || currentUserId == 0 || user == null || user.pastas == null) {
      // Se não há dados completos no UserHelper, podemos considerar isso como não autenticado
      // ou que os dados de pastas não foram carregados no login.
      // Neste cenário, se o AuthWrapper já passou, o ideal é que o UserHelper já tenha as pastas.
      // Se não tiver, pode ser um erro de lógica anterior ou dados corrompidos.
      throw ApiException('Dados do usuário ou pastas não disponíveis no cache local. Por favor, faça login novamente.', statusCode: 401, body: '');
    }

    // Retorna as pastas que foram salvas no UserHelper durante o login
    return user.pastas!;
  }

  /// Função para recuperar os detalhes de UMA pasta específica (e suas imagens/caminho).
  /// Este método usa o endpoint `getFolderDetails` e é para ser usado na AlbunsCriadosPage.
  Future<Folder> getFolderDetails(int folderId) async {
    final String? token = TokenHelper().token;
    final int currentUserId = TokenHelper().userId;

    if (token == null || token.isEmpty || currentUserId == 0) {
      throw ApiException('Usuário não autenticado para buscar detalhes da pasta.', statusCode: 401, body: '');
    }

    final url = Uri.parse(ApiEndpoints.getFolderDetails(folderId));
    foundation.debugPrint('Buscando detalhes da pasta: $folderId em $url');

    final responseBody = await _sendRequest(
      () => _httpClient.get(
        url,
        headers: _getHeaders(includeContentType: true),
      ),
      errorMessage: 'Falha ao recuperar detalhes da pasta.',
    );

    if (responseBody.containsKey('data') && responseBody['data'] is Map<String, dynamic>) {
      final Map<String, dynamic> folderData = responseBody['data'] as Map<String, dynamic>;
      return Folder.fromMap(folderData);
    } else {
      throw ApiException(
        'Formato de resposta inesperado para detalhes da pasta: chave "data" ausente ou inválida.',
        statusCode: responseBody['statusCode'] as int? ?? 0,
        body: json.encode(responseBody),
      );
    }
  }
}
