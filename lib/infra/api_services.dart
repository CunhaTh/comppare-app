// lib/infra/api_services.dart

import 'dart:convert';
import 'dart:developer';
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/models/image_model.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/models/folder_model.dart';

import '../models/models.dart'; // Para o modelo Folder

/// Uma classe de serviço para interagir com a API do seu backend.
class ApiService {
  final http.Client _httpClient;

  ApiService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _getHeaders({bool includeContentType = true}) {
    final String? authToken = TokenHelper().token;
    foundation.debugPrint(
        'ApiService: Token sendo acessado em _getHeaders: $authToken');
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
      foundation.debugPrint(
          'Aviso: Token de autenticação não disponível no TokenHelper.');
    }
    return headers;
  }

  // lib/infra/api_services.dart
  Future<Map<String, dynamic>> _sendRequest(
    Future<http.Response> Function() requestFunction, {
    String? successMessage,
    String? errorMessage,
    bool decodeJson = true,
  }) async {
    try {
      final response =
          await requestFunction().timeout(const Duration(seconds: 20));

      foundation.debugPrint(
          '[_sendRequest] Response Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decodeJson) {
          final Map<String, dynamic> responseBody =
              json.decode(response.body) as Map<String, dynamic>;
          if (responseBody.containsKey('codRetorno') &&
              (responseBody['codRetorno'] == 200 ||
                  responseBody['codRetorno'] == 201)) {
            return responseBody;
          } else {
            throw ApiException(
              responseBody['message'] ??
                  (successMessage ?? 'Erro desconhecido na API.'),
              statusCode: response.statusCode,
              body: response.body,
            );
          }
        } else {
          return {
            'status': 'success',
            'statusCode': response.statusCode,
            'body': response.body
          };
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
          serverMessage = errorBody['message'] ??
              errorBody['errors']?.toString() ??
              serverMessage;
        } catch (_) {
          serverMessage =
              response.body.isNotEmpty ? response.body : serverMessage;
        }

        throw ApiException(
          errorMessage ??
              'Falha na requisição: $serverMessage (Status ${response.statusCode}).',
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

  /// Função para autenticar o usuário.
  /// Salva o token e o ID do usuário no TokenHelper e o objeto User completo no UserHelper.
  Future<Map<String, dynamic>> authenticateUser(
      String cpf, String senha) async {
    final url = Uri.parse(ApiEndpoints.authenticateUser);
    foundation.debugPrint('Tentando autenticar usuário: $cpf');
    foundation.debugPrint('Tentando autenticar usuário: $cpf');
    foundation.debugPrint('URL da requisição: $url');
    foundation.debugPrint(
        'Corpo da requisição: ${jsonEncode({'cpf': cpf, 'senha': senha})}');
    foundation
        .debugPrint('Cabeçalhos: ${_getHeaders(includeContentType: true)}');

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

    if (responseBody.containsKey('token') &&
        responseBody['token'] is String &&
        responseBody.containsKey('dados') &&
        responseBody['dados'] is Map<String, dynamic>) {
      final String token = responseBody['token'] as String;
      final Map<String, dynamic> userData =
          responseBody['dados'] as Map<String, dynamic>;

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
      if (responseBody.containsKey('pastas') &&
          responseBody['pastas'] is List) {
        final List<dynamic> pastasJson =
            responseBody['pastas'] as List<dynamic>;
        // Aqui, convertemos para o modelo Folder, que é usado na PrincipalPage
        loggedInUser.pastas = pastasJson
            .map((item) => Folder.fromMap(item as Map<String, dynamic>))
            .toList();
        foundation.debugPrint(
            'ApiService: Pastas encontradas na resposta de autenticação: ${loggedInUser.pastas?.length}');
      } else {
        loggedInUser.pastas = [];
        foundation.debugPrint(
            'ApiService: Nenhuma pasta encontrada na resposta de autenticação.');
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

  // lib/infra/api_services.dart
  Future<Map<String, dynamic>> getFolderById(int folderId) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/folders/$folderId');
    return _sendRequest(
      () => _httpClient.get(url, headers: _getHeaders()),
      successMessage: 'Pasta carregada com sucesso.',
      errorMessage: 'Falha ao carregar pasta.',
    );
  }

  // lib/infra/api_services.dart
  Future<Map<String, dynamic>> createFolder({
    int? parentFolderId,
    required int idUsuario,
    required String folderName,
    List<String>? tags, // Adiciona suporte a tags
  }) async {
    final url = Uri.parse(ApiEndpoints.createFolder);
    foundation.debugPrint(
        '[_createFolder] Requisição para criar pasta/subpasta em: $url com nome: $folderName, parentFolderId: $parentFolderId');

    final body = {
      'idUsuario': idUsuario,
      'nomePasta': folderName,
      if (parentFolderId != null) 'parentFolderId': parentFolderId,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    };

    return _sendRequest(
      () => _httpClient.post(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Pasta/subpasta criada com sucesso.',
      errorMessage: 'Falha ao criar pasta/subpasta.',
    );
  }

  Future<Map<String, dynamic>> deleteFolder(int idUsuario, int idPasta) async {
    final url = Uri.parse(ApiEndpoints.deleteFolder);
    foundation
        .debugPrint('Requisição para excluir pasta em: $url, ID: $idPasta');

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
    foundation
        .debugPrint('Requisição para excluir imagem em: $url, ID: $idImagem');

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
      throw ApiException(
          'Dados do usuário ou pastas não disponíveis no cache local. Por favor, faça login novamente.',
          statusCode: 401,
          body: '');
    }
    return user.pastas!;
  }

  Future<List<Folder>> fetchSubfolders(int parentFolderId) async {
    final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.recoverFolder}?idPasta=$parentFolderId');
    final response = await _sendRequest(
      () => _httpClient.get(url, headers: _getHeaders()),
      successMessage: 'Subpastas carregadas com sucesso.',
      errorMessage: 'Falha ao carregar subpastas.',
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> subfolders = data['subpastas'] as List<dynamic>? ?? [];
    debugPrint('[_fetchSubfolders] Subpastas retornadas pela API: $subfolders');

    return subfolders.map((subfolder) {
      return Folder.fromMap({
        'id': subfolder['id'],
        'nome': subfolder['nome'],
        'caminho': subfolder['path'] ?? subfolder['pasta_caminho'],
        'idPastaPai': parentFolderId,
        'imagens': subfolder['imagens'] ?? [],
        'subpastas': [],
      });
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
              takenAt: DateTime.now().toIso8601String(),
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

  Future<Map<String, dynamic>> createSubFolder({
    required int parentFolderId,
    required int idUsuario,
    required String folderName,
    required String
        parentFolderPath, // Novo parâmetro para o caminho da pasta pai
    List<String>? tags,
  }) async {
    final url = Uri.parse(ApiEndpoints.createFolder);
    String nomePasta = folderName.trim();

    // Constrói o nomePasta usando o caminho da pasta pai
    if (parentFolderPath.isNotEmpty) {
      final parentName = parentFolderPath
          .split('/')
          .last; // Extrai o nome da pasta pai (ex.: "PASTAFOLDER")
      nomePasta = '$parentName/$folderName';
    } else {
      // Fallback: tenta obter o nome da pasta pai via API
      try {
        final parentFolder = await _getParentFolderDetails(parentFolderId);
        if (parentFolder != null && parentFolder['nome'] != null) {
          nomePasta = '${parentFolder['nome']}/$folderName';
        }
      } catch (e) {
        foundation
            .debugPrint('[_createSubFolder] Erro ao buscar pasta pai: $e');
      }
    }

    foundation.debugPrint(
        '[_createSubFolder] Requisição para criar subpasta em: $url com nome: $nomePasta, parentFolderId: $parentFolderId');

    final body = {
      'idUsuario': idUsuario,
      'nomePasta': nomePasta, // Usa a hierarquia completa
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    };

    return _sendRequest(
      () => _httpClient.post(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Subpasta criada com sucesso.',
      errorMessage: 'Falha ao criar subpasta.',
    );
  }

// Função de renovação de token (ajuste conforme necessário)
  Future<void> _refreshTokenIfNeeded() async {
    final token = TokenHelper().token;
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
              base64Url.decode(base64Url.normalize(parts[1])) as String);
          final expiry = payload['exp'] as int? ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (expiry < now + 300) {
            // Renova se faltar 5 minutos ou menos
            final user = UserHelper().user;
            if (user?.cpf != null && user?.senha != null) {
              await authenticateUser(user!.cpf!, user.senha!); // Reautentica
            }
          }
        }
      } catch (e) {
        foundation
            .debugPrint('[_refreshTokenIfNeeded] Erro ao verificar token: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _getParentFolderDetails(
      int parentFolderId) async {
    final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/pasta/recuperar?idPasta=$parentFolderId');
    try {
      final response = await _sendRequest(
        () => _httpClient.get(url, headers: _getHeaders()),
        successMessage: 'Detalhes da pasta pai carregados.',
        errorMessage: 'Falha ao carregar detalhes da pasta pai.',
      );
      foundation
          .debugPrint('[_getParentFolderDetails] Resposta da API: $response');
      return response;
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        foundation.debugPrint(
            '[_getParentFolderDetails] Pasta pai não encontrada para ID: $parentFolderId');
        return null;
      }
      rethrow;
    }
  }

// lib/infra/api_services.dart
  Future<Map<String, dynamic>> fetchFolderDetails(int folderId) async {
    final url =
        Uri.parse('${ApiEndpoints.baseUrl}/pasta/recuperar?idPasta=$folderId');
    return _sendRequest(
      () => _httpClient.get(
        url,
        headers: _getHeaders(includeContentType: true),
      ),
      errorMessage: 'Falha ao recuperar detalhes da pasta.',
    );
  }

  Future<Map<String, dynamic>> createPaymentWithCard(
      PaymentModel payment) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/vendas/criar-assinatura');
    log("URL DA ASSINATURA: $url || BODY ENVIADO: ${jsonEncode(payment.toMap())}");
    log("CABEÇALHOS: ${_getHeaders(includeContentType: true)}");
    return _sendRequest(
      () => _httpClient.post(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode(payment.toMap()),
      ),
      successMessage: 'Assinatura criada com sucesso.',
      errorMessage: 'Falha ao criar assinatura.',
    );
  }

  Future<Map<String, dynamic>> createPaymentWithPix({
    required int userId,
    required int planId,
  }) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/pix/enviar');
    log("URL DA ASSINATURA PIX: $url || BODY ENVIADO: ${jsonEncode({
          'usuario': userId,
          'plano': planId,
        })}");

    return _sendRequest(
      () => _httpClient.post(
        url,
        headers: _getHeaders(includeContentType: true),
        body: jsonEncode({
          'usuario': userId,
          'plano': planId,
        }),
      ),
      successMessage: 'Pix enviado com sucesso.',
      errorMessage: 'Falha ao enviar pix.',
    );
  }
}
