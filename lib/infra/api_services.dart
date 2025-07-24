// lib/infra/api_services.dart

import 'dart:convert';
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/models/image_model.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:http/http.dart' as http;
import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/models/folder_model.dart'; // Para o modelo Folder

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

    // Para MultipartRequest, o Content-Type é definido automaticamente pelo http.MultipartRequest
    // Não precisamos defini-lo explicitamente aqui para requisições multipart.
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

      // Cria o objeto User
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
        // Aqui, convertemos para o modelo Folder, que é usado na PrincipalPage
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
  /// Este método agora obtém as pastas do UserHelper, que foram salvas durante o login.
  Future<List<Folder>> getAllFoldersForUser() async {
    final User? user = UserHelper().user;

    if (user == null || user.pastas == null) {
      throw ApiException('Dados do usuário ou pastas não disponíveis no cache local. Por favor, faça login novamente.', statusCode: 401, body: '');
    }
    return user.pastas!;
  }

  /// NOVO MÉTODO: Função para buscar as "subpastas" (ImageGroups) e imagens de uma pasta pai.
  /// Este método fará a chamada para o endpoint `getFolderDetails` e converterá a resposta.
  ///
  /// Assumimos que o endpoint `getFolderDetails` retorna UMA pasta e suas imagens diretas.
  /// Se você precisa de uma lista de subpastas aninhadas, seu backend precisará de um endpoint
  /// que retorne uma estrutura de lista de pastas.
  Future<List<ImageGroup>> fetchSubfoldersAndImages(int parentFolderId) async {
    final String? token = TokenHelper().token;
    final int currentUserId = TokenHelper().userId;

    if (token == null || token.isEmpty || currentUserId == 0) {
      throw ApiException('Usuário não autenticado para buscar subpastas.', statusCode: 401, body: '');
    }

    // Chama o endpoint que retorna os detalhes de UMA pasta específica (e suas imagens)
    final url = Uri.parse(ApiEndpoints.getFolderDetails(parentFolderId));
    foundation.debugPrint('Buscando subpastas/imagens para a pasta ID: $parentFolderId em $url');

    final responseBody = await _sendRequest(
      () => _httpClient.get(
        url,
        headers: _getHeaders(includeContentType: true),
      ),
      errorMessage: 'Falha ao recuperar subpastas e imagens.',
    );

    // A resposta para getFolderDetails deve ter a estrutura de uma única pasta
    // Ex: {"codRetorno":200,"message":"OK","data":{ "id":..., "nome":..., "caminho":..., "imagens": [...] }}
    if (responseBody.containsKey('data') && responseBody['data'] is Map<String, dynamic>) {
      final Map<String, dynamic> folderData = responseBody['data'] as Map<String, dynamic>;
      
      // Converte a pasta retornada em um ImageGroup
      final ImageGroup imageGroup = ImageGroup.fromMap(folderData);
      
      // Retorna uma lista contendo apenas este ImageGroup.
      // Se seu backend retornar múltiplas subpastas, você precisará adaptar esta lógica.
      return [imageGroup];
    } else {
      throw ApiException(
        'Formato de resposta inesperado para detalhes da pasta: chave "data" ausente ou inválida.',
        statusCode: responseBody['statusCode'] as int? ?? 0,
        body: json.encode(responseBody),
      );
    }
  }

  /// Função para fazer upload de imagens para uma pasta específica.
  Future<List<MyImage>> uploadImages({
    required List<PickedFileItem> images,
    required int folderId,
  }) async {
    final url = Uri.parse(ApiEndpoints.uploadImages);
    final String? authToken = TokenHelper().token;
    // O ID do usuário não é mais enviado como campo, assumimos que o backend o obtém do token.
    // final int userId = TokenHelper().userId; 

    if (authToken == null || authToken.isEmpty) { // Removido userId == 0 da condição
      throw ApiException('Usuário não autenticado para upload de imagens.', statusCode: 401, body: '');
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
      if (fileItem.bytes != null && fileItem.platformFile.name != null) {
        foundation.debugPrint('Upload: Adicionando arquivo ${fileItem.platformFile.name} (tamanho: ${fileItem.bytes!.length} bytes) ao campo image[]');
        request.files.add(
          http.MultipartFile.fromBytes(
            'image[]', // ⭐ CORREÇÃO AQUI: Nome do campo mudado para 'image[]'
            fileItem.bytes!,
            filename: fileItem.platformFile.name,
          ),
        );
      } else {
        foundation.debugPrint('Upload: Aviso - Arquivo ${fileItem.platformFile.name} (índice $i) possui bytes nulos ou nome nulo. Ignorando.');
      }
    }

    foundation.debugPrint('Enviando ${request.files.length} imagens para a pasta $folderId...');

    final response = await _httpClient.send(request).timeout(const Duration(seconds: 60));
    final responseBody = await response.stream.bytesToString();

    foundation.debugPrint('Upload Response Status: ${response.statusCode}, Body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
      if (jsonResponse.containsKey('codRetorno') && jsonResponse['codRetorno'] == 200) {
        if (jsonResponse.containsKey('image_paths') && jsonResponse['image_paths'] is List) { // ⭐ CORREÇÃO AQUI: Espera 'image_paths'
          // A API retorna apenas os caminhos das imagens, não o objeto MyImage completo.
          // Precisamos adaptar a criação de MyImage.
          List<MyImage> uploadedImages = [];
          for (var path in jsonResponse['image_paths']) {
            // Assumimos que o backend não retorna o ID da imagem aqui,
            // então usaremos um ID temporário ou 0, e um takenAt padrão.
            // Se o backend retornar o ID e takenAt, você precisará ajustar.
            uploadedImages.add(MyImage(
              id: 0, // ID temporário, pois a API não o retorna neste ponto
              path: path as String,
              takenAt: DateTime.now().toIso8601String(), // Data atual como fallback
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
        serverMessage = errorBody['message'] ?? errorBody['errors']?.toString() ?? serverMessage;
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

  /// Função para criar uma pasta (subálbum) com tags.
  Future<int> createSubFolder({
    required String folderName,
    required List<String> tags,
    int? parentFolderId, // Adicionado para criar subpastas
  }) async {
    final url = Uri.parse(ApiEndpoints.createFolder);
    final String? authToken = TokenHelper().token;
    final int userId = TokenHelper().userId;

    if (authToken == null || authToken.isEmpty || userId == 0) {
      throw ApiException('Usuário não autenticado para criar pasta.', statusCode: 401, body: '');
    }

    final Map<String, dynamic> body = {
      'idUsuario': userId,
      'nomePasta': folderName,
      'tags': tags,
    };
    if (parentFolderId != null) {
      body['parentFolderId'] = parentFolderId;
    }

    foundation.debugPrint('Requisição para criar subpasta em: $url com nome: $folderName, parentId: $parentFolderId');

    final responseBody = await _sendRequest(
      () => _httpClient.post(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Pasta criada com sucesso.',
      errorMessage: 'Falha ao criar pasta.',
    );

    if (responseBody.containsKey('data') && responseBody['data'] is Map<String, dynamic> &&
        responseBody['data'].containsKey('id')) {
      return responseBody['data']['id'] as int;
    } else {
      throw ApiException(
        'Resposta inesperada ao criar pasta: ID da pasta não encontrado.',
        statusCode: responseBody['statusCode'] as int? ?? 0,
        body: json.encode(responseBody),
      );
    }
  }
}
