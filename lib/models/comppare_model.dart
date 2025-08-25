import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// IMPORTANTE:
// Adapte as classes ApiEndpoints, UserHelper e as outras dependências
// para a sua implementação completa. Este é um exemplo funcional.

/// Representa o modelo para uma tag dentro da requisição de comparação.
/// Corresponde a um objeto JSON como: { "id_tag": 56, "valor": "100" }
class ComparacaoTag {
  final int idTag;
  final String valor;

  ComparacaoTag({required this.idTag, required this.valor});

  Map<String, dynamic> toJson() {
    return {
      'id_tag': idTag,
      'valor': valor,
    };
  }
}

/// Representa o modelo da requisição completa para a API de comparação.
/// Corresponde ao corpo JSON fornecido.
class ComparacaoRequest {
  final int idUsuario;
  final int idPhoto;
  final String dataComparacao;
  final List<ComparacaoTag> tags;

  ComparacaoRequest({
    required this.idUsuario,
    required this.idPhoto,
    required this.dataComparacao,
    required this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'id_photo': idPhoto,
      'data_comparacao': dataComparacao,
      'tags': tags.map((tag) => tag.toJson()).toList(),
    };
  }
}
