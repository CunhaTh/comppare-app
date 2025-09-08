import 'package:application_progress/models/image_model.dart';

class Folder {
  final int id;
  String nome;
  final String caminho;
  String? principalPageDisplayName;
  final int? idPastaPai;
  List<ImageModel>? imagens;
  List<String>? tags;
  List<Folder>? subpastas;

  Folder({
    required this.id,
    required this.nome,
    required this.caminho,
    this.principalPageDisplayName,
    this.idPastaPai,
    this.imagens,
    this.tags,
    this.subpastas,
  });

  String get pageDisplayName {
    if (nome.isEmpty) return 'Pasta sem nome';
    final parts = nome.split('/');
    if (parts.length <= 1) return nome;
    return parts[1];
  }

  String? get albunsCriadosPageDisplayName {
    if (nome.isEmpty) return 'SubPasta sem nome';
    final parts = nome.split('/');
    return parts.last;
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    List<String> loadedTags = [];
    if (map['tags'] != null && map['tags'] is List) {
      for (var tagJson in map['tags']) {
        if (tagJson is Map<String, dynamic>) {
          // =======================================================================
          // AJUSTE FINAL AQUI: Procura por 'nome' ou 'nomeTag'
          // =======================================================================
          final tagName = tagJson['nome'] ?? tagJson['nomeTag'];
          if (tagName != null) {
            loadedTags.add(tagName as String);
          }
          // =======================================================================
        }
      }
    }

    return Folder(
      id: map['id'] as int? ?? 0,
      nome: map['nome'] as String? ?? 'Pasta sem nome',
      caminho: map['path'] as String? ?? '',
      principalPageDisplayName: map['nome'] as String?,
      idPastaPai: map['idPastaPai'] as int?,
      imagens: (map['imagens'] as List<dynamic>?)
          ?.map((img) {
            if (img is Map<String, dynamic>) return ImageModel.fromMap(img);
            return null;
          })
          .whereType<ImageModel>()
          .toList(),
      tags: loadedTags,
      subpastas: (map['subpastas'] as List<dynamic>?)
          ?.map((sub) {
            if (sub is Map<String, dynamic>) return Folder.fromMap(sub);
            return null;
          })
          .whereType<Folder>()
          .toList(),
    );
  }

  factory Folder.createNew(String folderName, {String? userName}) {
    final fullName = userName != null ? '$userName/$folderName' : folderName;
    return Folder(
      id: DateTime.now().millisecondsSinceEpoch,
      nome: fullName,
      caminho: '/storage/app/public/$fullName',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'caminho': caminho,
      'principalPageDisplayName': principalPageDisplayName,
      'idPastaPai': idPastaPai,
      'imagens': imagens?.map((img) => img.toMap()).toList(),
      'tags': tags,
      'subpastas': subpastas?.map((sub) => sub.toMap()).toList(),
    };
  }
}