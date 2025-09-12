import 'dart:convert';

import 'package:flutter/foundation.dart';

class ImageSaveModel {
  final int idUsuario;
  final int idPhoto;
  final String dataComparacao;
  final List<Category> tags;
  ImageSaveModel({
    required this.idUsuario,
    required this.idPhoto,
    required this.dataComparacao,
    required this.tags,
  });

  ImageSaveModel copyWith({
    int? idUsuario,
    int? idPhoto,
    String? dataComparacao,
    List<Category>? tags,
  }) {
    return ImageSaveModel(
      idUsuario: idUsuario ?? this.idUsuario,
      idPhoto: idPhoto ?? this.idPhoto,
      dataComparacao: dataComparacao ?? this.dataComparacao,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id_usuario': idUsuario});
    result.addAll({'id_photo': idPhoto});
    result.addAll({'data_comparacao': dataComparacao});
    result.addAll({'tags': tags.map((x) => x.toMap()).toList()});

    return result;
  }

  factory ImageSaveModel.fromMap(Map<String, dynamic> map) {
    return ImageSaveModel(
      idUsuario: map['id_usuario']?.toInt() ?? 0,
      idPhoto: map['id_photo']?.toInt() ?? 0,
      dataComparacao: map['data_comparacao'] ?? '',
      tags: List<Category>.from(map['tags']?.map((x) => Category.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory ImageSaveModel.fromJson(String source) =>
      ImageSaveModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ImageSaveModel(id_usuario: $idUsuario, id_photo: $idPhoto, data_comparacao: $dataComparacao, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageSaveModel &&
        other.idUsuario == idUsuario &&
        other.idPhoto == idPhoto &&
        other.dataComparacao == dataComparacao &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return idUsuario.hashCode ^
        idPhoto.hashCode ^
        dataComparacao.hashCode ^
        tags.hashCode;
  }
}

class Category {
  final int idTag;
  final String valor;
  Category({
    required this.idTag,
    required this.valor,
  });

  Category copyWith({
    int? idTag,
    String? valor,
  }) {
    return Category(
      idTag: idTag ?? this.idTag,
      valor: valor ?? this.valor,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id_tag': idTag});
    result.addAll({'valor': valor});

    return result;
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      idTag: map['id_tag']?.toInt() ?? 0,
      valor: map['valor'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Category.fromJson(String source) =>
      Category.fromMap(json.decode(source));

  @override
  String toString() => 'Category(id_tag: $idTag, valor: $valor)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category && other.idTag == idTag && other.valor == valor;
  }

  @override
  int get hashCode => idTag.hashCode ^ valor.hashCode;
}
