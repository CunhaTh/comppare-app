// lib/models/folder_model.dart
import 'package:application_progress/models/image_model.dart'; // Importa ImageModel

class Folder {
  final int id;
  final String fullName; // Renomeado 'nome' para 'fullName' para armazenar a string original como "Luis_Pimenta/pimenta/upload0"
  final String caminho;
  List<ImageModel>? imagens; // Adicionado para armazenar as imagens dentro da pasta

  Folder({
    required this.id,
    required this.fullName,
    required this.caminho,
    this.imagens, // Torne opcional
  });

  // Converte o objeto Folder para um Map (para salvar no GetStorage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': fullName, // Use 'nome' para o JSON da API
      'caminho': caminho,
      'imagens': imagens?.map((img) => img.toMap()).toList(), // Serializa as imagens
    };
  }

  // Cria um objeto Folder a partir de um Map (lido do GetStorage ou da resposta da API)
  factory Folder.fromMap(Map<String, dynamic> map) { // Renomeado de fromJson para fromMap
    List<ImageModel>? parsedImagens;
    if (map.containsKey('imagens') && map['imagens'] is List) {
      parsedImagens = (map['imagens'] as List)
          .map((i) => ImageModel.fromMap(i as Map<String, dynamic>)) // Use fromMap para ImageModel
          .toList();
    }

    final id = map['id'] as int?;
    final receivedFullName = map['nome'] as String? ?? ''; // Get the full name from JSON
    final path = map['caminho'] as String? ?? '';

    if (id == null || receivedFullName.isEmpty || path.isEmpty) {
      throw FormatException('Dados da pasta inválidos recebidos da API: $map');
    }

    return Folder(
      id: id,
      fullName: receivedFullName,
      caminho: path,
      imagens: parsedImagens,
    );
  }

  // Getter para o nome principal a ser exibido na PrincipalPage
  String get principalPageDisplayName {
    final parts = fullName.split('/');
    // Se o nome for tipo "Usuario/PastaPrincipal/SubPasta", queremos "PastaPrincipal"
    // Se for "Usuario/PastaPrincipal", queremos "PastaPrincipal"
    // Se for "PastaSimples", queremos "PastaSimples"
    if (parts.length >= 2) {
      return parts[1]; // Retorna a segunda parte (ex: "PastaPrincipal")
    } else if (parts.isNotEmpty) {
      return parts.last; // Retorna a única parte (ex: "PastaSimples")
    }
    return "Pasta Raiz"; // Padrão para nome vazio
  }

  // Getter para o nome de exibição genérico (pode ser o mesmo que principalPageDisplayName ou adaptado)
  String get displayName => principalPageDisplayName; // Usando o mesmo para simplicidade

  // Este getter parece ser para o caminho completo da API, se necessário.
  String get apiFullName => caminho;
}
