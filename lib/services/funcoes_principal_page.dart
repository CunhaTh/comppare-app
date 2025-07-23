/*import 'dart:convert';

import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FuncoesPrincipalPage {
  Future<void> _addFolder(String folderName) async {
    final user = UserHelper.instance.user;
    if (user == null || user.id == null || !TokenHelper.instance.hasToken()) {
      throw Exception('Usuário inválido ou não autenticado.');
    }

    // Usando ApiEndpoints para a URL de criação de pasta
    final response = await http.post(
      Uri.parse(ApiEndpoints.createFolder), // Adicione este endpoint em ApiEndpoints
      headers: {
        'Authorization': 'Bearer ${TokenHelper.instance.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'idUsuario': user.id,
        'nomePasta': folderName,
      }),
    ).timeout(const Duration(seconds: 15));

    debugPrint('Resposta de /pasta/create: Status ${response.statusCode}, Corpo: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['codRetorno'] != 200) {
        throw Exception(body['message'] ?? 'API retornou um erro na criação da pasta.');
      }
    } else {
      throw Exception('Erro na requisição de criar pasta: Status ${response.statusCode}');
    }
  }  
}*/

