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

  /// Cria uma cópia do objeto `ImageModel`, permitindo a substituição
  /// de valores específicos. Essencial para a atualização de estado.
  ///
  /// COMO FUNCIONA:
  /// 1. Cria um novo mapa (`newMetadata`) baseado nos dados existentes para não perder nada.
  /// 2. Mescla (`addAll`) quaisquer novos metadados que sejam passados.
  /// 3. Atualiza campos específicos como a `date`, que tem prioridade.
  /// 4. Retorna uma instância COMPLETAMENTE NOVA de `ImageModel` com os dados combinados.
  ImageModel copyWith({
    int? id,
    String? url,
    Uint8List? imageData,
    bool? isSelected,
    Map<String, String>? metadata,
    String? date, // Parâmetro para atualizar a data diretamente.
  }) {
    // Começa com uma cópia dos metadados atuais para não perder dados.
    final newMetadata = Map<String, String>.from(this.metadata);

    // Se um novo mapa de metadados for fornecido, mescla os valores.
    if (metadata != null) {
      newMetadata.addAll(metadata);
    }

    // Se uma data específica for fornecida, ela tem prioridade.
    if (date != null) {
      newMetadata['date'] = date;
    }

    return ImageModel(
      id: id ?? this.id,
      url: url ?? this.url,
      imageData: imageData ?? this.imageData,
      isSelected: isSelected ?? this.isSelected,
      metadata: newMetadata,
    );
  }


  // Propriedades convenientes para acesso aos metadados, mantendo
  // a compatibilidade e a clareza.
  String? get date => metadata['date'];
  set date(String? value) => _setMetadata('date', value);

  String? get weight => metadata['weight'];
  set weight(String? value) => _setMetadata('weight', value);

  String? get waist => metadata['waist'];
  set waist(String? value) => _setMetadata('waist', value);

  String? get observation => metadata['observation'];
  set observation(String? value) => _setMetadata('observation', value);

  // Novo getter/setter para data_comparacao
  String? get dataComparacao => metadata['data_comparacao'];
  set dataComparacao(String? value) => _setMetadata('data_comparacao', value);

  /// Método auxiliar para definir metadados com validação.
  void _setMetadata(String key, String? value) {
    if (value != null) {
      metadata[key] = value;
    } else {
      metadata.remove(key);
    }
  }

  /// Construtor a partir de um mapa (ex.: API).
  ///
  /// Esta versão foi ajustada para mapear dinamicamente os metadados e suportar 'tags'.
  factory ImageModel.fromMap(Map<String, dynamic> map) {
    final Map<String, String> apiToInternalKeys = {
      'takenAt': 'date',
      'weight': 'weight',
      'waist': 'waist',
      'observation': 'observation',
      'data_comparacao': 'data_comparacao', // Novo mapeamento
    };

    final Map<String, String> newMetadata = {};
    map.forEach((key, value) {
      final internalKey = apiToInternalKeys[key] ?? key;
      if (value != null) {
        newMetadata[internalKey] = value.toString();
      }
    });

    // Se 'tags' vier da API como uma lista de mapas, converte para metadados
    final List<dynamic>? tags = map['tags'] as List<dynamic>?;
    if (tags != null) {
      for (var tag in tags) {
        if (tag is Map<String, dynamic> && tag['id_tag'] != null && tag['valor'] != null) {
          newMetadata[tag['id_tag'].toString()] = tag['valor'].toString();
        }
      }
    }

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
  /// Esta versão foi ajustada para incluir 'tags' como um campo separado, se necessário.
  Map<String, dynamic> toMap() {
    final Map<String, String> internalToApiKeys = {
      'date': 'takenAt',
      'weight': 'weight',
      'waist': 'waist',
      'observation': 'observation',
      'data_comparacao': 'data_comparacao',
    };

    final Map<String, dynamic> outputMap = {
      'id': id,
      'url': url,
    };

    // Converte metadados para o formato da API
    final List<Map<String, dynamic>> tags = [];
    metadata.forEach((key, value) {
      final apiFieldKey = internalToApiKeys[key] ?? key;
      if (apiFieldKey == 'takenAt' || apiFieldKey == 'data_comparacao' || apiFieldKey == 'weight' || apiFieldKey == 'waist' || apiFieldKey == 'observation') {
        outputMap[apiFieldKey] = value;
      } else {
        tags.add({'id_tag': key, 'valor': value}); // Adiciona como tag se não for um campo mapeado
      }
    });

    // Inclui 'tags' como campo separado, se houver
    if (tags.isNotEmpty) {
      outputMap['tags'] = tags;
    }

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
}

// Funções e classes auxiliares
class PickedFileItem {
  final PlatformFile platformFile;
  final Uint8List? bytes;

  PickedFileItem({required this.platformFile}) : bytes = platformFile.bytes;
}