// lib/models/tag_model.dart

class TagModel {
  final int id;
  final String nomeTag;

  TagModel({
    required this.id,
    required this.nomeTag,
  });

  factory TagModel.fromJson(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as int,
      nomeTag: map['nomeTag'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeTag': nomeTag,
    };
  }
}
