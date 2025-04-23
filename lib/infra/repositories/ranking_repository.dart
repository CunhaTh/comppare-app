import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_endponts.dart';
import '../token_helper.dart';
import '../user_helper.dart';

class RankingRepository {
  static Future<List?> getDataRanking() async {
    try {
      print('TOKEN> ${TokenHelper.instance.token}');
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
        return null;
      }

      final data = json.decode(response.body);
      final List<dynamic> planosJson = data['data'];
      // plans = planosJson.map((json) => Plano.fromJson(json)).toList();
      return [];
    } catch (e) {
      debugPrint('(Erro ao trazer os dados do ranking) $e');
      return null;
    }
  }

  static Future<bool> sendDataRanking({required int points}) async {
    try {
      var userId = UserHelper.instance.userId;
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
