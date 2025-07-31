import 'package:application_progress/models/image_model.dart'; // Nova ImageModel

class Folder {
  final int id;
  String? nome; // Removido 'late final' para permitir modificação
  final String caminho; // Caminho físico da pasta no servidor
  String? principalPageDisplayName;
  final int? idPastaPai;
  List<ImageModel>? imagens; // Substituído por List<ImageModel>
  List<String>? tags;
  List<String>? subpastas; // Suporte a subpastas com tags

  Folder({
    required this.id,
    this.nome,
    required this.caminho,
    this.principalPageDisplayName,
    this.idPastaPai,
    this.imagens,
    this.tags,
    this.subpastas,
  });

  // Getter para o nome a ser exibido na PrincipalPage
  String get pageDisplayName {
    if (nome == null || nome!.isEmpty) return 'Pasta sem nome';
    final parts = nome!.split('/');
    return parts.length > 1 ? parts[1] : nome!;
  }

  // Getter para o nome a ser exibido na AlbunsCriadosPage
  String? get albunsCriadosPageDisplayName {
    if (nome == null || nome!.isEmpty) return 'SubPasta sem nome';
    final parts = nome!.split('/');
    return parts.length > 1 ? parts.last : nome;
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    final folderName = map['nome'] as String?;
    return Folder(
      id: map['id'] as int? ?? 0,
      nome: folderName?.isNotEmpty == true ? folderName : null, // Só define se válido
      caminho: map['caminho'] as String? ?? '',
      principalPageDisplayName: map['principalPageDisplayName'] ?? folderName,
      idPastaPai: map['idPastaPai'] as int?,
      imagens: (map['imagens'] as List<dynamic>?)
          ?.map((img) => ImageModel.fromMap(img as Map<String, dynamic>))
          .toList(),
      tags: (map['tags'] as List<dynamic>?)
          ?.map((tag) => tag.toString())
          .toList(),
      subpastas: (map['subpastas'] as List<dynamic>?)
          ?.map((sub) => sub.toString())
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
      'subpastas': subpastas,
    };
  }
}