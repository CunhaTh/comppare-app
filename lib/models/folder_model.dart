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

// DENTRO DO SEU ARQUIVO folder_model.dart

factory Folder.fromMap(Map<String, dynamic> map) {
  // Lógica para carregar as tags, que já estava correta.
  List<String> loadedTags = [];
  if (map['tags'] != null && map['tags'] is List) {
    for (var tagJson in map['tags']) {
      if (tagJson is Map<String, dynamic>) {
        final tagName = tagJson['nome'] ?? tagJson['nomeTag'];
        if (tagName != null) {
          loadedTags.add(tagName as String);
        }
      }
    }
  }

  // --- INÍCIO DA CORREÇÃO DE ROBUSTEZ ---

  // Processa a lista de subpastas de forma segura
  List<Folder> parsedSubpastas = [];
  if (map.containsKey('subpastas') && map['subpastas'] is List) {
    // Se a chave 'subpastas' existe e é uma lista, nós a processamos.
    parsedSubpastas = (map['subpastas'] as List)
        .map((subpastaJson) => Folder.fromMap(subpastaJson as Map<String, dynamic>))
        .toList();
  }
  // Se a chave não existir ou não for uma lista, 'parsedSubpastas' continuará sendo uma lista vazia.

  // Processa a lista de imagens de forma segura
  List<ImageModel> parsedImagens = [];
  if (map.containsKey('imagens') && map['imagens'] is List) {
    // A mesma lógica segura para a lista de imagens.
    parsedImagens = (map['imagens'] as List)
        .map((imagemJson) => ImageModel.fromMap(imagemJson as Map<String, dynamic>))
        .toList();
  }
  
  // --- FIM DA CORREÇÃO DE ROBUSTEZ ---

  return Folder(
    id: map['id'] as int? ?? 0,
    nome: map['nome'] as String? ?? 'Pasta sem nome',
    caminho: map['path'] as String? ?? '',
    principalPageDisplayName: map['nome'] as String?,
    idPastaPai: map['idPastaPai'] as int?,
    
    // Usa as listas seguras que criamos acima.
    subpastas: parsedSubpastas,
    imagens: parsedImagens,
    tags: loadedTags,
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