import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_endponts.dart';
import '../token_helper.dart';
import '../user_helper.dart';

class RankingRepository {
  static Future<List<RankingItemModel>> getDataRanking() async {
    try {
      print('TOKEN: ${TokenHelper.instance.token}');
      final response = await http.get(
        Uri.parse(ApiEndpoints.rankingClassification),
        headers: {
          // 'Authorization': 'Bearer ${TokenHelper.instance.token}',
          'content-type': 'application/json',
        },
      );

      print('BODY: ${response.body}');
      print('LINK: ${ApiEndpoints.rankingClassification}');

      if (response.statusCode != 200) {
        debugPrint(
          '(Erro ao trazer os dados do ranking) CODE: ${response.statusCode}, MESSAGE: ${response.reasonPhrase}',
        );
        return [];
      }

      final data = json.decode(response.body);
      return data.map((json) => RankingItemModel.fromMap(json)).toList();
    } catch (e) {
      debugPrint('(Erro ao trazer os dados do ranking) $e');
      return [];
    }
  }

  static Future<bool> sendDataRanking({required int points}) async {
    try {
      var userId = UserHelper.instance.user?.id;
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse(ApiEndpoints.updateRanking),
        body: {'usuario': userId, 'pontos': points},
      );

      // print('BODY: ${response.body}');

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
  final num pontos;
  int? position;

  RankingItemModel({
    required this.nome,
    required this.pontos,
  });

  factory RankingItemModel.fromMap(Map<String, dynamic> map) {
    return RankingItemModel(
      nome: map['nome'],
      pontos: map['pontos'],
    );
  }
}

List<RankingItemModel> getPositions(List<RankingItemModel> ranking) {
  ranking.sort((a, b) => b.pontos.compareTo(a.pontos));

  for (int i = 0; i < ranking.length; i++) {
    ranking[i].position = i + 1;
  }

  return ranking;
}
