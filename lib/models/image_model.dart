import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' as devtools;
import 'package:http/http.dart' as http;

/// Representa um modelo de imagem com metadados associados.
///
/// Esta classe foi refatorada para centralizar todos os metadados
/// em um único mapa `metadata`, tornando o modelo mais flexível e
/// escalável.
class ImageModel {
  final int id;
  String url;
  Uint8List? imageData;
  bool isSelected;
  // Mapa centralizado para todos os metadados da imagem.
  Map<String, String> metadata;

  /// Construtor principal para o modelo de imagem.
  ImageModel({
    this.id = 0,
    this.url = '',
    this.imageData,
    this.isSelected = false,
    Map<String, String>? metadata,
  }) : this.metadata = metadata ?? {};

  // Propriedades convenientes para acesso aos metadados, mantendo
  // a compatibilidade e a clareza.
  String? get date => metadata['date'];
  set date(String? value) =>
      value != null ? metadata['date'] = value : metadata.remove('date');

  String? get weight => metadata['weight'];
  set weight(String? value) =>
      value != null ? metadata['weight'] = value : metadata.remove('weight');

  String? get waist => metadata['waist'];
  set waist(String? value) =>
      value != null ? metadata['waist'] = value : metadata.remove('waist');

  String? get observation => metadata['observation'];
  set observation(String? value) => value != null
      ? metadata['observation'] = value
      : metadata.remove('observation');

  /// Construtor a partir de um mapa (ex.: API).
  ///
  /// Esta versão foi simplificada para mapear dinamicamente os metadados,
  /// garantindo que qualquer campo adicional da API seja capturado
  /// no mapa de metadados.
  factory ImageModel.fromMap(Map<String, dynamic> map) {
    // Mapeamento explícito das chaves da API para as chaves internas do app.
    final Map<String, String> apiToInternalKeys = {
      'takenAt': 'date',
      'weight': 'weight',
      'waist': 'waist',
      'observation': 'observation',
    };

    final Map<String, String> newMetadata = {};
    map.forEach((key, value) {
      final internalKey = apiToInternalKeys[key] ?? key;
      if (value != null) {
        newMetadata[internalKey] = value.toString();
      }
    });

    // Se 'customTags' vier da API, mesclamos com os metadados existentes.
    final Map<String, dynamic>? customTags = map['customTags'] as Map<String, dynamic>?;
    if (customTags != null) {
      customTags.forEach((key, value) {
        if (value != null) {
          newMetadata[key.toString()] = value.toString();
        }
      });
    }

    return ImageModel(
      id: map['id'] as int? ?? 0,
      url: map['url'] as String? ?? map['path'] as String? ?? '',
      metadata: newMetadata,
    );
  }

  /// Construtor a partir de MyImage (compatibilidade).
  /// Mantém a lógica original, criando uma nova instância a partir de outra.
  factory ImageModel.fromMyImage(ImageModel myImage, {Uint8List? imageData}) {
    return ImageModel(
      id: myImage.id,
      url: myImage.url,
      imageData: imageData,
      metadata: Map.from(myImage.metadata), // Cria uma cópia do mapa
    );
  }

  /// Construtor a partir de PickedFileItem (arquivos locais).
  /// Mantém a lógica original.
  factory ImageModel.fromPickedFile(PlatformFile platformFile) {
    return ImageModel(
      id: 0,
      url: '',
      imageData: platformFile.bytes,
      metadata: {},
    );
  }

  /// Converte o modelo para um mapa (ex.: envio à API).
  ///
  /// Esta versão usa um mapeamento explícito para converter chaves internas
  /// para as chaves esperadas pela API, garantindo consistência.
  Map<String, dynamic> toMap() {
    final Map<String, String> internalToApiKeys = {
      'date': 'takenAt',
      'weight': 'weight',
      'waist': 'waist',
      'observation': 'observation',
    };

    final Map<String, dynamic> outputMap = {
      'id': id,
      'url': url,
    };

    metadata.forEach((key, value) {
      final apiFieldKey = internalToApiKeys[key] ?? key;
      outputMap[apiFieldKey] = value;
    });

    // Se a API espera um campo 'customTags' separado para tags dinâmicas.
    // Isso depende do formato da sua API. Mantive a lógica para ilustrar.
    // outputMap['customTags'] = metadata;

    return outputMap;
  }

  /// Carrega os dados de imagem a partir de uma URL.
  /// A lógica de carregamento de dados da imagem não precisa ser alterada.
  Future<void> loadImageData() async {
    if (imageData != null && imageData!.isNotEmpty) {
      devtools.debugPrint(
          'Usando imageData existente para URL: $url (${imageData!.length} bytes)');
      return;
    }

    if (url.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          imageData = response.bodyBytes;
          devtools.debugPrint(
              'Imagem carregada da URL: $url (${imageData!.length} bytes)');
        } else {
          devtools.debugPrint(
              'Falha ao carregar imagem da URL $url: Status ${response.statusCode}');
          imageData = Uint8List(0);
        }
      } catch (e) {
        devtools.debugPrint('Erro ao carregar imagem da URL $url: $e');
        imageData = Uint8List(0);
      }
    } else {
      devtools.debugPrint('URL vazia para imagem ID: $id');
      imageData = Uint8List(0);
    }
  }
}

// Função auxiliar (deve estar em um lugar acessível, ex.: um util ou service)
Future<Uint8List?> _loadImageBytesFromUrl(String url) async {
  // Implementação existente (ex.: usando http.get)
  // Retorna Uint8List ou null em caso de erro
  return null; // Placeholder, substitua pela lógica real
}// Funções e classes auxiliares
class PickedFileItem {
  final PlatformFile platformFile;
  final Uint8List? bytes;

  PickedFileItem({required this.platformFile}) : bytes = platformFile.bytes;
}
