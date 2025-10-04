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

  // --- NOVOS CAMPOS PARA COMPARTILHAMENTO ---
  final bool pastaCompartilhada;
  final bool proprietarioPasta;
  // ----------------------------------------

  Folder({
    required this.id,
    required this.nome,
    required this.caminho,
    this.principalPageDisplayName,
    this.idPastaPai,
    this.imagens,
    this.tags,
    this.subpastas,
    // Inicialize os novos campos
    this.pastaCompartilhada = false, 
    this.proprietarioPasta = false, 
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
    // Lógica para carregar as tags...
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

    // Processa a lista de subpastas de forma segura...
    List<Folder> parsedSubpastas = [];
    if (map.containsKey('subpastas') && map['subpastas'] is List) {
      parsedSubpastas = (map['subpastas'] as List)
          .map((subpastaJson) => Folder.fromMap(subpastaJson as Map<String, dynamic>))
          .toList();
    }

    // Processa a lista de imagens de forma segura...
    List<ImageModel> parsedImagens = [];
    if (map.containsKey('imagens') && map['imagens'] is List) {
      parsedImagens = (map['imagens'] as List)
          .map((imagemJson) => ImageModel.fromMap(imagemJson as Map<String, dynamic>))
          .toList();
    }

    return Folder(
      id: map['id'] as int? ?? 0,
      nome: map['nome'] as String? ?? 'Pasta sem nome',
      caminho: map['path'] as String? ?? '',
      principalPageDisplayName: map['nome'] as String?,
      idPastaPai: map['idPastaPai'] as int?,

      // --- ATUALIZAÇÃO CHAVE: Carrega os novos campos ---
      // Se os campos não vierem da API, eles serão 'false' por padrão.
      pastaCompartilhada: map['pastaCompartilhada'] as bool? ?? false,
      proprietarioPasta: map['proprietarioPasta'] as bool? ?? false,
      // ---------------------------------------------------

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
      // Novos álbuns criados localmente DEVEM ser do proprietário e não compartilhados.
      pastaCompartilhada: false, 
      proprietarioPasta: true, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'caminho': caminho,
      'principalPageDisplayName': principalPageDisplayName,
      'idPastaPai': idPastaPai,
      // Adicionando os novos campos no toMap (útil para debug e persistência local, se houver)
      'pasta_compartilhada': pastaCompartilhada,
      'proprietario_pasta': proprietarioPasta,
      // ... resto do mapa
      'imagens': imagens?.map((img) => img.toMap()).toList(),
      'tags': tags,
      'subpastas': subpastas?.map((sub) => sub.toMap()).toList(),
    };
  }
}