// lib/models/folder_model.dart

class Folder {
  final int id;
  final String nome; // Nome completo da pasta, ex: "Thiago Gomes_Cunha/FirstFolder/firsSubfolder"
  final String caminho; // Caminho físico da pasta no servidor

  Folder({
    required this.id,
    required this.nome,
    required this.caminho,
  });

  // Getter para o nome a ser exibido na PrincipalPage (o nome da pasta principal)
  String get principalPageDisplayName {
    // Exemplo de nome: "Thiago Gomes_Cunha/home/u757410616/domains/comppare.com.br/public_html/api-comppare/storage/app/public/Thiago_Gomes_Cunha/PastaPai/SubPasta/247Sub"
    // Ou: "Thiago Gomes_Cunha/PastaPai"
    // Ou: "Thiago Gomes_Cunha/NovaPasta"

    // ⭐ CORREÇÃO AQUI: Certifica-se de que 'nome' não é nulo antes de split
    final String safeNome = nome; // 'nome' já é final e não-nulo, mas para clareza
    final parts = safeNome.split('/');
    
    // Primeiro, tenta remover a parte do caminho do servidor se ela estiver presente
    String cleanPath = safeNome;
    final serverPathPattern = RegExp(r'.*\/storage\/app\/public\/[^\/]+\/?'); // Padrão para "storage/app/public/NomeDoUsuario/"
    final match = serverPathPattern.firstMatch(safeNome);

    if (match != null) {
      cleanPath = safeNome.substring(match.end);
    } else {
      // Se não encontrou o padrão do servidor, tenta remover o primeiro segmento (que pode ser o nome do usuário)
      if (parts.length > 1) {
        cleanPath = parts.skip(1).join('/');
      }
    }

    // Agora, do caminho limpo, pegamos o primeiro segmento
    final cleanParts = cleanPath.split('/');
    if (cleanParts.isNotEmpty && cleanParts[0].isNotEmpty) {
      return cleanParts[0]; // Retorna o primeiro segmento válido
    }

    return safeNome; // Retorna o nome completo como fallback se não conseguir parsear
  }

  // Getter para o nome a ser exibido na AlbunsCriadosPage (a última subpasta no caminho)
  String get albunsCriadosPageDisplayName {
    final parts = nome.split('/');
    if (parts.isNotEmpty) {
      return parts.last; // Retorna a última parte (o nome da subpasta mais aninhada)
    }
    return nome; // Retorna o nome completo se não houver partes
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      // ⭐ CORREÇÃO AQUI: Adicionado null-check e fallback para 'nome' e 'caminho'
      id: map['id'] as int,
      nome: map['nome'] as String? ?? '', // Garante que nome não seja nulo
      caminho: map['caminho'] as String? ?? '', // Garante que caminho não seja nulo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'caminho': caminho,
    };
  }
}
