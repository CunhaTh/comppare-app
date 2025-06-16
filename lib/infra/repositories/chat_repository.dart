import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_endponts.dart';
import '../token_helper.dart';

class ChatRepository {
  static Future<List<ChatQuestionModel>> getChatQuestions() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.getChatQuestions),
        headers: {
          'Authorization': 'Bearer ${TokenHelper.instance.token}',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '(Erro ao trazer as perguntas do chat) CODE: ${response.statusCode}, MESSAGE: ${response.reasonPhrase}',
        );
        return [];
      }

      final data = json.decode(response.body)['data'] as List;
      return data
          .map<ChatQuestionModel>((json) => ChatQuestionModel.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('(Erro ao trazer as perguntas do chat) $e');
      return [];
    }
  }

  static Future<bool> sendChatQuestion({
    required String question,
    required String answer,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.sendChatQuestion),
        body: {'pergunta': question, 'resposta': answer},
        headers: {
          'Authorization': 'Bearer ${TokenHelper.instance.token}',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '(Erro ao enviar a pergunta) CODE: ${response.statusCode}, MESSAGE: ${response.reasonPhrase}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('(Erro ao enviar a pergunta) $e');
      return false;
    }
  }
}

class ChatQuestionModel {
  final String question;
  final String answer;

  ChatQuestionModel({
    required this.question,
    required this.answer,
  });

  factory ChatQuestionModel.fromMap(Map<String, dynamic> map) {
    return ChatQuestionModel(
      question: map['pergunta'] ?? '',
      answer: map['resposta'] ?? '',
    );
  }
}
