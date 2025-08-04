import 'package:application_progress/models/image_model.dart'; // Nova ImageModel

class Folder {
  final int id;
  String nome; // Tornado obrigatório com valor padrão
  final String caminho; // Caminho físico da pasta no servidor
  String? principalPageDisplayName;
  final int? idPastaPai;
  List<ImageModel>? imagens; // Substituído por List<ImageModel>
  List<String>? tags;
  List<Folder>? subpastas; // Alterado para List<Folder>

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

  // Getter para o nome a ser exibido na PrincipalPage (nome da pasta raiz)
  String get pageDisplayName {
    if (nome.isEmpty) return 'Pasta sem nome';
    final parts = nome.split('/');
    if (parts.length <= 1) return nome; // Retorna o nome completo se não houver hierarquia
    return parts[1]; // Retorna o primeiro nome após o usuário (pasta raiz)
  }

  String? get albunsCriadosPageDisplayName {
    if (nome.isEmpty) return 'SubPasta sem nome';
    final parts = nome.split('/');
    return parts.last; // Remove a condição idPastaPai para teste
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    final folderId = map['pasta_id'] as int? ?? 0; // Corrigido para 'pasta_id'
    final folderName = map['pasta_nome'] as String? ?? map['estrutura_completa'] as String? ?? 'Pasta sem nome'; // Prioriza 'pasta_nome' ou 'estrutura_completa'
    final folderPath = map['pasta_caminho'] as String? ?? ''; // Corrigido para 'pasta_caminho'
    return Folder(
      id: folderId,
      nome: folderName.isNotEmpty ? folderName : 'Pasta sem nome',
      caminho: folderPath,
      principalPageDisplayName: map['estrutura_completa'] ?? folderName,
      idPastaPai: map['idPastaPai'] as int?,
      imagens: (map['imagens'] as List<dynamic>?)?.map((img) {
        if (img is Map<String, dynamic>) return ImageModel.fromMap(img);
        return null;
      }).whereType<ImageModel>().toList(),
      tags: (map['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList(),
      subpastas: (map['subpastas'] as List<dynamic>?)?.map((sub) {
        if (sub is Map<String, dynamic>) return Folder.fromMap(sub);
        return null;
      }).whereType<Folder>().toList(),
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