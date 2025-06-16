import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:application_progress/planos.dart';

import '../api_endponts.dart';
import '../token_helper.dart';
import '../user_helper.dart';

class PlansRepository {
  static Future<List<Plano>> getPlans() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.getPlans),
        headers: {
          'Authorization': 'Bearer ${TokenHelper.instance.token}',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '(Erro ao trazer os planos) CODE: ${response.statusCode}, MESSAGE: ${response.reasonPhrase}',
        );
        return [];
      }

      final data = json.decode(response.body);
      final List<dynamic> planosJson = data['data'];
      return planosJson.map((json) => Plano.fromJson(json)).toList();
    } catch (e) {
      debugPrint('(Erro ao trazer os planos) $e');
      return [];
    }
  }

  static Future<bool> getCheckUpdatePlan(int newPlanId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.checkUpdatePlan),
        body: {
          "cpf": UserHelper.instance.user?.cpf,
          "plano": newPlanId.toString(),
        },
        headers: {
          'Authorization': 'Bearer ${TokenHelper.instance.token}',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '(Erro ao trazer os planos) CODE: ${response.statusCode}, MESSAGE: ${response.reasonPhrase}',
        );
        return false;
      }

      final data = json.decode(response.body);
      return data['changePlan'] ?? false;
    } catch (e) {
      debugPrint('(Erro ao trazer os planos) $e');
      return false;
    }
  }
}
