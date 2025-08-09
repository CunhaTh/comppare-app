import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' as devtools;
import 'package:http/http.dart' as http; // Para PlatformFile

class ImageModel {
  final int
      id; // Identificador único (opcional, pode ser nulo para novos arquivos)
  String url; // URL ou caminho da imagem (pode ser vazio para arquivos locais)
  Uint8List? imageData; // Dados binários, carregados ou de arquivo local
  bool isSelected; // Estado de seleção na UI
  String? date; // Data personalizada (derivado de takenAt ou editável)
  String? weight; // Peso associado
  String? waist; // Cintura associada
  String? observation; // Observação
  Map<String, String> customCategorias; // Tags personalizadas

  ImageModel({
    this.id = 0, // 0 como padrão para novos itens
    this.url = '',
    this.imageData,
    this.isSelected = false,
    this.date,
    this.weight,
    this.waist,
    this.observation,
    this.customCategorias = const {},
    required String takenAt,
  });

  // Construtor a partir de um mapa (ex.: API)
  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'] as int? ?? 0,
      url: map['url'] as String? ?? map['path'] ?? '',
      date: (map['takenAt'] as String?)?.split(' ')[0],
      customCategorias: (map['customTags'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
      takenAt: '',
    );
  }

  // Construtor a partir de MyImage (compatibilidade)
  factory ImageModel.fromMyImage(ImageModel myImage, {Uint8List? imageData}) {
    return ImageModel(
      id: myImage.id,
      url: myImage.url,
      imageData: imageData,
      date: myImage.date,
      weight: 'N/A',
      waist: 'N/A',
      observation: 'N/A',
      customCategorias: {},
      takenAt: '',
    );
  }

  // Construtor a partir de PickedFileItem (arquivos locais)
  factory ImageModel.fromPickedFile(PlatformFile platformFile) {
    return ImageModel(
      id: 0, // Novo item, sem ID ainda
      url: '', // Sem URL inicial
      imageData: platformFile.bytes,
      date: null,
      weight: null,
      waist: null,
      observation: null,
      customCategorias: {},
      takenAt: '',
    );
  }

  // Converte para mapa (ex.: envio à API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'takenAt': date, // Usa date como substituto para takenAt
      'customTags': customCategorias,
    };
  }

  // Método para carregar imageData a partir da URL (se não estiver presente)
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

class PickedFileItem {
  final PlatformFile platformFile;
  final Uint8List? bytes;

  PickedFileItem({required this.platformFile}) : bytes = platformFile.bytes;
}
