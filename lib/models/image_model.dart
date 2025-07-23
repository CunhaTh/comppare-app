// lib/models/image_model.dart
import 'package:file_picker/file_picker.dart'; // Importar PlatformFile
import 'dart:typed_data'; // Importar Uint8List
import 'dart:convert'; // Para base64Decode

class ImageModel { // Renomeado de MyImage para ImageModel
  final int id;
  final String path; // URL completa da imagem
  final String? thumbUrl; // Miniatura, se houver
  final String? takenAt; // Data de criação/captura, se houver
  final Uint8List? bytes; // Para armazenar os dados binários da imagem.
  final String? date; // Data customizada para ImageItem
  final String? weight; // Peso customizado para ImageItem
  final String? waist; // Cintura customizada para ImageItem
  final String? observation; // Observação customizada para ImageItem
  final Map<String, String>? customTags; // Tags customizadas para ImageItem


  ImageModel({
    required this.id,
    required this.path,
    this.thumbUrl,
    this.takenAt,
    this.bytes,
    this.date,
    this.weight,
    this.waist,
    this.observation,
    this.customTags,
  });

  // Converte o objeto ImageModel para um Map (para salvar no GetStorage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'thumb_url': thumbUrl,
      'taken_at': takenAt,
      'imageDataBase64': bytes != null ? base64Encode(bytes!) : null, // Converte bytes para base64
      'date': date,
      'weight': weight,
      'waist': waist,
      'observation': observation,
      'customTags': customTags,
    };
  }

  // Cria um objeto ImageModel a partir de um Map (lido do GetStorage ou da resposta da API)
  factory ImageModel.fromMap(Map<String, dynamic> map) { // Renomeado de fromJson para fromMap
    Uint8List? decodedBytes;
    if (map['imageDataBase64'] != null && map['imageDataBase64'] is String) {
      try {
        decodedBytes = base64Decode(map['imageDataBase64']);
      } catch (e) {
        print("Erro ao decodificar base64 para ImageModel: $e");
      }
    }

    return ImageModel(
      id: map['id'] as int,
      path: map['path'] as String,
      // Se 'thumb_url' não vier, use 'path' como fallback
      thumbUrl: map['thumb_url'] as String? ?? map['path'] as String?,
      takenAt: map['taken_at'] as String?,
      bytes: decodedBytes,
      date: map['date'] as String?,
      weight: map['weight'] as String?,
      waist: map['waist'] as String?,
      observation: map['observation'] as String?,
      customTags: (map['customTags'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

// A classe ImageGroup parece ser específica para a tela AlbunsCriadosPage
// e não é usada para serialização/desserialização de pastas no UserHelper.
// Se ela for usada apenas em AlbunsCriadosPage, ela pode permanecer lá ou em um arquivo dedicado.
// Por enquanto, vou mantê-la aqui, mas com a ressalva.
class ImageGroup {
  final int folderId; // 'id' da pasta no JSON
  final String folderName; // 'nome' da pasta no JSON
  final List<ImageModel> images; // Usando ImageModel
  final List<String> tags; // Se houver tags associadas à pasta no JSON
  final String albunsCriadosDisplayName;


  ImageGroup({
    required this.folderId,
    required this.folderName,
    this.images = const [],
    this.tags = const [],
    required this.albunsCriadosDisplayName,
  });

  factory ImageGroup.fromJson(Map<String, dynamic> json) {
    List<ImageModel> parsedImages = [];
    if (json['imagens'] is List) {
      parsedImages = (json['imagens'] as List)
          .map((i) => ImageModel.fromMap(i as Map<String, dynamic>)) // Usando fromMap
          .toList();
    }

    List<String> parsedTags = [];
    if (json.containsKey('tags') && json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((tag) => tag.toString()).toList();
    }

    final String fullFolderName = json['nome'] as String;
    final List<String> folderNameParts = fullFolderName.split('/');
    final String displayAlbumName = folderNameParts.isNotEmpty ? folderNameParts.last : "Subálbum";

    return ImageGroup(
      folderId: json['id'] as int,
      folderName: fullFolderName,
      images: parsedImages,
      tags: parsedTags,
      albunsCriadosDisplayName: displayAlbumName,
    );
  }
}

// DEFINIÇÃO ÚNICA DE PickedFileItem
class PickedFileItem {
  final PlatformFile platformFile;
  PickedFileItem({required this.platformFile});
}
