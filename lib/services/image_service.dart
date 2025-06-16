import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:application_progress/infra/user_helper.dart';

class ImageService {
  // Função auxiliar para recuperar o token
  String? _getAuthToken() {
    final user = UserHelper.instance.user;
    final token = user?.token;
    debugPrint('Token recuperado: $token');
    return token;
  }

  Future<List<String>> uploadImages({
    required List<dynamic> images,
    required int userId,
    String? subAlbumName,
    int? folderId,
  }) async {
    final Uri url = Uri.parse("https://api.comppare.com.br/api/imagem/upload");
    final String? authToken = _getAuthToken();
    List<String> uploadedUrls = [];

    if (authToken == null) {
      throw Exception('Token de autenticação não encontrado. Faça login novamente.');
    }

    if (folderId == null) {
      throw Exception('ID da pasta não fornecido. Não é possível fazer upload das imagens.');
    }

    try {
      for (var image in images) {
        var request = http.MultipartRequest('POST', url)
          ..fields['idUsuario'] = userId.toString()
          ..fields['idPasta'] = folderId.toString();

        if (subAlbumName != null) {
          request.fields['subAlbumName'] = subAlbumName;
        }

        request.headers['Authorization'] = 'Bearer $authToken';
        request.headers['Content-Type'] = 'multipart/form-data';

        if (kIsWeb || image is Uint8List) {
          request.files.add(http.MultipartFile.fromBytes(
            'imagem',
            image is Uint8List ? image : image as List<int>,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ));
        } else if (image is File) {
          request.files.add(await http.MultipartFile.fromPath('imagem', image.path));
        } else {
          throw Exception('Tipo de imagem não suportado: ${image.runtimeType}');
        }

        var response = await request.send().timeout(const Duration(seconds: 30));
        var responseBody = await response.stream.bytesToString();

        debugPrint('Resposta da API (uploadImages): $responseBody');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (responseBody.isEmpty) {
            throw Exception('Resposta da API está vazia');
          }

          dynamic data;
          try {
            data = jsonDecode(responseBody);
          } catch (e) {
            throw Exception('Erro ao parsear JSON: $responseBody');
          }

          if (data is Map<String, dynamic>) {
            final dynamic urlData = data['data'];
            if (urlData is Map<String, dynamic> && urlData['url'] is String) {
              uploadedUrls.add(urlData['url'] as String);
            } else {
              throw Exception('URL da imagem não retornada pela API: $responseBody');
            }
          } else {
            throw Exception('Resposta da API inválida (não é um Map): $responseBody');
          }
        } else {
          throw Exception('Falha ao fazer upload da imagem: ${response.statusCode} - $responseBody');
        }
      }
    } catch (e) {
      debugPrint('Erro no uploadImages: $e');
      throw Exception('Erro ao fazer upload das imagens: $e');
    }

    return uploadedUrls;
  }

  Future<void> createSubAlbum({
    required int userId,
    required String folderName,
    required String subAlbumName,
    required List<String> tags,
    required List<String> imageUrls,
    int? folderId,
  }) async {
    final Uri url = Uri.parse("https://api.comppare.com.br/api/pasta/create");
    final String? authToken = _getAuthToken();

    if (authToken == null) {
      throw Exception('Token de autenticação não encontrado. Faça login novamente.');
    }

    if (folderId == null) {
      throw Exception('ID da pasta não fornecido. Não é possível criar o subálbum na API.');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'idUsuario': userId,
          'nomePasta': '$folderName/$subAlbumName',
          'tags': tags,
          'imagens': imageUrls,
          'idPasta': folderId,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('A requisição demorou muito para responder.');
      });

      debugPrint('Resposta da API (createSubAlbum): ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao criar subálbum: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro no createSubAlbum: $e');
      throw Exception('Erro ao criar subálbum: $e');
    }
  }

  Future<void> saveImage({
    required int idPasta,
    required String imageName,
  }) async {
    final Uri url = Uri.parse("https://api.comppare.com.br/api/imagens/salvar");
    final String? authToken = _getAuthToken();

    if (authToken == null) {
      throw Exception('Token de autenticação não encontrado. Faça login novamente.');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'image': imageName,
          'idPasta': idPasta,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('A requisição demorou muito para responder.');
      });

      debugPrint('Resposta da API (saveImage): ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Falha ao salvar imagem: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro no saveImage: $e');
      throw Exception('Erro ao salvar imagem: $e');
    }
  }
}