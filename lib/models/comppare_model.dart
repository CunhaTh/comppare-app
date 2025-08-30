class ComparacaoModel {
  final int id;
  final int idPhoto;
  final String dataComparacao;
  final List<Map<String, dynamic>> tags;

  ComparacaoModel({
    required this.id,
    required this.idPhoto,
    required this.dataComparacao,
    required this.tags,
  });

  factory ComparacaoModel.fromJson(Map<String, dynamic> json) {
    return ComparacaoModel(
      id: json['id'] as int,
      idPhoto: json['id_photo'] as int, // Corrigido de 'idPhoto' para 'id_photo'
      dataComparacao: json['data_comparacao'] as String,
      tags: (json['tags'] as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }
}