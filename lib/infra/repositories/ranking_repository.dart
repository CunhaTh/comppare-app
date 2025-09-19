// lib/infra/repositories/ranking_repository.dart

import 'dart:convert';
import 'dart:developer';

import 'package:application_progress/models/folder_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api_endponts.dart';
import '../api_services.dart';
import '../token_helper.dart';
import '../user_helper.dart';

// ==========================================================
// PASSO 1: Transformando em uma classe Singleton
// Isso garante que teremos apenas uma instância "inteligente" do repositório no app.
// ==========================================================
class RankingRepository {
  RankingRepository._privateConstructor();
  static final RankingRepository instance = RankingRepository._privateConstructor();

  // ==========================================================
  // PASSO 2: Adicionando as dependências necessárias
  // ==========================================================
  final ApiService _apiService = ApiService();

  // ==========================================================
  // AJUSTE: Métodos agora são de instância (não são mais 'static')
  // ==========================================================

  /// Busca a lista de usuários já classificada pela API.
  Future<List<RankingItemModel>> getDataRanking() async {
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
      List<RankingItemModel> items = data
          .map<RankingItemModel>((json) => RankingItemModel.fromMap(json))
          .toList();

      // LÓGICA MOVIDA: A atribuição de posições agora acontece aqui dentro.
      for (int i = 0; i < items.length; i++) {
        items[i].position = i + 1;
      }

      return items;
    } catch (e) {
      debugPrint('(Erro ao trazer os dados do ranking) $e');
      return [];
    }
  }

  /// Envia a pontuação total de um usuário para a API.
  Future<bool> sendDataRanking({required int points}) async {
    try {
      var user = UserHelper().user;

      // Regra de negócio: não envia pontuação para o plano gratuito
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

  // ==========================================================
  // NOVOS MÉTODOS INTELIGENTES
  // ==========================================================

  /// NOVO MÉTODO INTELIGENTE 1: Adiciona pontos de eventos (compare, salvar, etc.)
  /// e dispara o recálculo total.
/// Adiciona pontos de um evento a um contexto específico (álbum/subálbum).
Future<void> addEventPoints(int pointsToAdd, {String? contextId}) async {
  // Se não houver contexto, não fazemos nada.
  // Isso evita que pontos sejam adicionados "no vácuo".
  if (contextId == null) {
    log('Contexto nulo para addEventPoints. Nenhum ponto adicionado.');
    return;
  }
  
  log('Adicionando $pointsToAdd pontos de evento ao contexto $contextId...');
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // A chave agora é única para cada álbum/subálbum. Ex: 'event_points_album_123'
    final String key = 'event_points_$contextId';
    
    final int currentEventPoints = prefs.getInt(key) ?? 0;
    final int newEventPointsTotal = currentEventPoints + pointsToAdd;
    await prefs.setInt(key, newEventPointsTotal);

    await recalculateAndUpdateScore();
  } catch (e) {
    log('Falha ao adicionar pontos de evento: $e');
  }
}

/// Calcula a pontuação TOTAL (Estado + Eventos) e envia para o ranking.
Future<void> recalculateAndUpdateScore() async {
  log('Iniciando recálculo de pontos...');
  try {
    final List<Folder> allFolders = await _apiService.getAllFoldersForUser();
    log('DEBUG: A API retornou ${allFolders.length} álbuns para o recálculo.');

    int albumPoints = allFolders.length * 1;
    int subAlbumPoints = 0;
    int photoWithTagPoints = 0;

    // INÍCIO DA MUDANÇA
    int totalEventScore = 0;
    final prefs = await SharedPreferences.getInstance();

    for (final folder in allFolders) {
      // Soma os pontos de evento salvos para este álbum principal
      totalEventScore += prefs.getInt('event_points_album_${folder.id}') ?? 0;

      final subs = folder.subpastas ?? [];
      subAlbumPoints += subs.length * 1;
      for (final subfolder in subs) {
        // Soma os pontos de evento salvos para este subálbum
        totalEventScore += prefs.getInt('event_points_subalbum_${subfolder.id}') ?? 0;

        if (subfolder.imagens != null) {
          for (final imagem in subfolder.imagens!) {
            if (imagem.metadata != null && imagem.metadata!.isNotEmpty) {
              photoWithTagPoints += 2;
            }
          }
        }
      }
    }
    // FIM DA MUDANÇA

    final int stateScore = albumPoints + subAlbumPoints + photoWithTagPoints;
    final int totalPoints = stateScore + totalEventScore;

    await sendDataRanking(points: totalPoints);
    log('Pontuação total (Estado + Eventos) atualizada para: $totalPoints pontos.');

  } catch (e) {
    log('Falha ao recalcular e enviar a pontuação: $e');
  }
}
}

// O modelo de dados continua o mesmo
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
      pontos: map['pontos']?.toString() ?? '0',
    );
  }
}

// A função global getPositions não é mais necessária, pois sua lógica
// foi movida para dentro do método getDataRanking.