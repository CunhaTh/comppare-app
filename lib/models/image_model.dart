

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart'; // Para PlatformFile


// Modelo para representar uma imagem retornada pela API
class MyImage {
  final int id;
  final String path; // URL da imagem
  final String takenAt; // Data em que a imagem foi tirada

  MyImage({
    required this.id,
    required this.path,
    required this.takenAt,
  });

  factory MyImage.fromMap(Map<String, dynamic> map) {
    return MyImage(
      id: map['id'] as int,
      path: map['path'] as String,
      // ⭐ CORREÇÃO AQUI: Garante que 'takenAt' não seja nulo.
      // Se a API não retornar 'takenAt', use uma string vazia ou a data atual.
      takenAt: map['takenAt'] as String? ?? '', // Adicionado null-check e fallback
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'takenAt': takenAt,
    };
  }
}

// Modelo para agrupar imagens em um "subálbum"
class ImageGroup {
  final int folderId;
  final String folderName; // Nome completo da pasta, ex: "Thiago Gomes_Cunha/PastaPai/SubPasta"
  final String folderPath; // Caminho físico da pasta no servidor
  final List<MyImage> images;
  final List<String> tags; // Tags associadas a este grupo/subálbum

  ImageGroup({
    required this.folderId,
    required this.folderName,
    required this.folderPath,
    required this.images,
    this.tags = const [],
  });

  // Getter para o nome a ser exibido na AlbunsCriadosPage
  String get albunsCriadosDisplayName {
    final parts = folderName.split('/');
    if (parts.isNotEmpty) {
      return parts.last; // Retorna a última parte (o nome da subpasta mais aninhada)
    }
    return folderName; // Retorna o nome completo se não houver partes
  }

  factory ImageGroup.fromMap(Map<String, dynamic> map) {
    // ⭐ CORREÇÃO AQUI: Adicionado null-check para 'nome' e 'caminho'
    final String nome = map['nome'] as String? ?? '';
    final String caminho = map['caminho'] as String? ?? '';

    return ImageGroup(
      folderId: map['id'] as int,
      folderName: nome,
      folderPath: caminho,
      images: (map['imagens'] as List<dynamic>?)
              ?.map((e) => MyImage.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      // ⭐ CORREÇÃO AQUI: Adicionado null-check para 'tags'
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'folderId': folderId,
      'folderName': folderName,
      'folderPath': folderPath,
      'images': images.map((e) => e.toMap()).toList(),
      'tags': tags,
    };
  }
}

// Modelo para representar um arquivo selecionado localmente antes do upload
class PickedFileItem {
  final PlatformFile platformFile;
  final Uint8List? bytes;

  PickedFileItem({required this.platformFile}) : bytes = platformFile.bytes;
}
