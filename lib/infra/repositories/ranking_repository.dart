import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_endponts.dart';
import '../token_helper.dart';
import '../user_helper.dart';

class RankingRepository {
  static Future<List<RankingItemModel>> getDataRanking() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.rankingClassification),
        headers: {
          'Authorization': 'Bearer ${TokenHelper().token}',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '(Erro ao trazer os dados do ranking) CODE: ${response.statusCode}, MESSAGE: ${response.reasonPhrase}',
        );
        return [];
      }

      final data = json.decode(response.body) as List;
      return data
          .map<RankingItemModel>((json) => RankingItemModel.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('(Erro ao trazer os dados do ranking) $e');
      return [];
    }
  }

  static Future<bool> sendDataRanking({required int points}) async {
    try {
      var user = UserHelper().user;

      if (user?.idPlano == 1) return true;

      if (user?.id == null) return false;

      final response = await http.post(
        Uri.parse(ApiEndpoints.updateRanking),
        body: {'usuario': user!.id.toString(), 'pontos': points.toString()},
        headers: {
          'Authorization': 'Bearer ${TokenHelper().token}',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '(Erro ao atualizar os dados do ranking) CODE: ${response.statusCode}, MESSAGE: ${response.reasonPhrase}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('(Erro ao atualizar os dados do ranking) $e');
      return false;
    }
  }
}

class RankingItemModel {
  final String nome;
  final String pontos;
  int? position;

  RankingItemModel({
    required this.nome,
    required this.pontos,
    this.position,
  });

  factory RankingItemModel.fromMap(Map<String, dynamic> map) {
    return RankingItemModel(
      nome: map['nome'],
      pontos: map['pontos'] ?? '0',
    );
  }
}

List<RankingItemModel> getPositions(List<RankingItemModel> ranking) {
  for (int i = 0; i < ranking.length; i++) {
    ranking[i].position = i + 1;
  }

  return ranking;
}
