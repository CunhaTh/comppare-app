// lib/services/image_service.dart

import 'dart:convert';
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/api_services.dart'; // Certifique-se que ApiService existe e tem os métodos esperados
import 'package:application_progress/models/folder_model.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'package:application_progress/models/image_model.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/api_endponts.dart';

/// Serviço responsável por interagir com a API de imagens,
/// gerenciando operações como criação de pastas, upload, busca e exclusão.
class ImageService {
  final ApiService _apiService;
  final http.Client _httpClient;

  ImageService({ApiService? apiService, http.Client? httpClient})
      : _apiService = apiService ?? ApiService(),
        _httpClient = httpClient ?? http.Client();

  /// Retorna os cabeçalhos HTTP padrão. Usado para requisições multipart.
  /// O Content-Type é geralmente adicionado automaticamente pelo http.MultipartRequest.
  Map<String, String> _getHeadersForMultipart() {
    final String? authToken = TokenHelper().token;
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    } else {
      foundation.debugPrint('Aviso: Token de autenticação não disponível no TokenHelper.');
    }
    return headers;
  }

  /// Cria uma nova pasta ou subpasta na galeria do usuário.
  /// O `folderName` pode incluir a hierarquia (ex: "PastaPrincipal/Subpasta").
  ///
  /// Retorna o `idPasta` da pasta criada.
  /// Lança [ApiException] em caso de falha.
  Future<int> createFolder({
    required String folderName,
    required List<String> tags, // Tags são passadas, mas a implementação do ApiService pode ignorá-las se o backend não suportar para pastas
  }) async {
    final int currentUserId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || currentUserId == 0) {
      throw ApiException('Usuário não autenticado ou ID de usuário inválido para criar pasta.', statusCode: 401);
    }

    try {
      // ⭐ Delega para o ApiService, que deve lidar com o endpoint e a lógica de criação de pasta.
      // Assumindo que ApiService.createFolder recebe userId e folderName e retorna um Map.
      final response = await _apiService.createFolder(currentUserId, folderName);
      
      // O ApiService já deve ter tratado a resposta HTTP e lançado ApiException para erros.
      // Aqui, esperamos que 'response' seja o corpo decodificado da resposta,
      // e que ele contenha 'idPasta'.
      if (response.containsKey('idPasta') && response['idPasta'] is int) {
        return response['idPasta'] as int;
      } else {
        throw ApiException(
          'API retornou sucesso na criação da pasta, mas sem ID de pasta válido.',
          statusCode: 200, // Assumimos 200 OK se chegou aqui, mas sem o ID esperado
          body: json.encode(response),
        );
      }
    } on ApiException {
      rethrow; // Re-lança a exceção já tratada pelo ApiService
    } catch (e) {
      throw ApiException('Erro inesperado ao criar pasta: ${e.toString()}', statusCode: 0);
    }
  }

  /// Recupera os detalhes de uma pasta específica (incluindo suas imagens).
  /// Este método é para a "Tela de Subpastas" para carregar o conteúdo da pasta selecionada.
  Future<List<Folder>> fetchFolderDetails() async {
    final int currentUserId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || currentUserId == 0) {
      throw ApiException('Usuário não autenticado para buscar detalhes da pasta.', statusCode: 401);
    }

    try {
      // ⭐ Delega para o ApiService. O ApiService deve retornar um objeto ImageGroup.
      return await _apiService.getAllFoldersForUser();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erro ao buscar detalhes da pasta: ${e.toString()}', statusCode: 0);
    }
  }

  /// Lista todas as pastas (principais e subpastas, ou apenas principais dependendo da API) do usuário.
  /// Este método é para a "Tela Principal" (Álbuns Criados)
  /// e não deve receber `idFolder`, pois busca todas as pastas do usuário.
  /// ⭐ AJUSTE: Removido o parâmetro `idFolder` que era redundante para "todas as pastas".
  Future<List<Folder>> fetchAllFolders() async {
    final int currentUserId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || currentUserId == 0) {
      throw ApiException('Usuário não autenticado para listar pastas.', statusCode: 401);
    }

    try {
      // ⭐ Delega para o ApiService. O ApiService.recuperaFolder deve buscar todas as pastas associadas ao usuário logado.
      return await _apiService.getAllFoldersForUser();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erro ao buscar todas as pastas: ${e.toString()}', statusCode: 0);
    }
  }

  /// Exclui uma pasta e todo o seu conteúdo.
  Future<void> deleteFolder(int folderId) async {
    final int currentUserId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || currentUserId == 0) {
      throw ApiException('Usuário não autenticado para excluir pasta.', statusCode: 401);
    }

    try {
      // ⭐ Delega para o ApiService, que deve ter o método deleteFolder
      await _apiService.deleteFolder(currentUserId, folderId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erro ao excluir pasta: ${e.toString()}', statusCode: 0);
    }
  }

  /// Faz o upload de uma lista de imagens para uma pasta específica.
  Future<List<ImageGroup>> uploadImages({
    required List<PickedFileItem> images,
    required int folderId,
  }) async {
    final int currentUserId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || currentUserId == 0) {
      throw ApiException('Usuário não autenticado para fazer upload de imagens.', statusCode: 401);
    }

    final uri = Uri.parse(ApiEndpoints.uploadImages);
    foundation.debugPrint('Enviando imagens para: $uri, para a pasta: $folderId, pelo usuário: $currentUserId');

    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_getHeadersForMultipart());

    request.fields['idUsuario'] = currentUserId.toString();
    request.fields['idPasta'] = folderId.toString(); // ⭐ Usando folderId passado como parâmetro

    for (var item in images) {
      final file = item.platformFile;
      final String? mimeType = lookupMimeType(file.name);

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image', // Nome do campo esperado pela API para o arquivo
            file.bytes!,
            filename: file.name,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // Nome do campo esperado pela API para o arquivo
            file.path!,
            filename: file.name,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ),
        );
      } else {
        foundation.debugPrint('Aviso: Arquivo ${file.name} sem bytes ou caminho, será ignorado.');
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      foundation.debugPrint('Upload Images Response Status: ${response.statusCode}');
      foundation.debugPrint('Upload Images Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decodedResponse = json.decode(response.body);

        // Adaptação para o JSON do Insomnia ou outros formatos comuns de sucesso
        if (decodedResponse is List) {
          // Se a API retornar uma lista diretamente de objetos de imagem
          return decodedResponse.map((json) => ImageGroup.fromMap(json as Map<String, dynamic>)).toList();
        } else if (decodedResponse is Map<String, dynamic> && decodedResponse.containsKey('data') && decodedResponse['data'] is List) {
          // Se a API retornar um objeto com uma chave 'data' contendo a lista de imagens
          return (decodedResponse['data'] as List<dynamic>)
              .map((json) => ImageGroup.fromMap(json as Map<String, dynamic>))
              .toList();
        } else if (decodedResponse is Map<String, dynamic> && decodedResponse.containsKey('image_paths') && decodedResponse['image_paths'] is List) {
          // ⭐ Adaptação específica para o JSON do Insomnia (ex: {"image_paths": ["path1", "path2"]})
          final List<dynamic> imagePaths = decodedResponse['image_paths'] as List<dynamic>;
          // Cria objetos MyImage a partir dos paths. O ID pode ser um placeholder (0)
          // se a API não retornar IDs de imagem no momento do upload.
          return imagePaths.map((path) => ImageGroup(folderPath: path.toString(), folderId: 0, folderName: 'NOME DA PASTA')).toList();
        } else {
          throw ApiException(
            'Formato de resposta inesperado após o upload de imagens.',
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      } else {
        throw ApiException(
          'Falha no upload das imagens: Status ${response.statusCode} - ${response.body}',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Erro de conexão ao fazer upload das imagens: ${e.message}', statusCode: 0);
    } on FormatException {
      throw ApiException('Resposta inválida do servidor durante o upload de imagens.', statusCode: 0);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Erro inesperado ao fazer upload das imagens: ${e.toString()}', statusCode: 0);
    }
  }
}