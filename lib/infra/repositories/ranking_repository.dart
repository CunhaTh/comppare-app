// lib/infra/repositories/ranking_repository.dart

import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/user_helper.dart';

class RankingRepository {
  RankingRepository._privateConstructor();
  static final RankingRepository instance = RankingRepository._privateConstructor();

  final ApiService _apiService = ApiService();

  // ==========================================================
  // PONTOS: Defina os valores para cada ação aqui
  // ==========================================================
  static const int pointsPerAlbum = 1;
  static const int pointsPerSubAlbum = 1;
  static const int pointsPerPhotoWithTag = 2;
  static const int pointsPhoto = 5;
  static const int pointsPhotoCompatilhar = 20;

  /// Busca, processa e retorna a lista de usuários classificada.
  Future<List<RankingItemModel>> getDataRanking() async {
    log('Buscando dados do ranking...');
    try {
      final List<dynamic> data = await _apiService.getRankingClassification();
      
      List<RankingItemModel> items = data
          .map<RankingItemModel>((json) => RankingItemModel.fromMap(json))
          .toList();

      for (int i = 0; i < items.length; i++) {
        items[i].position = i + 1;
      }
      return items;
    } catch (e) {
      log('Falha em getDataRanking: $e');
      return [];
    }
  }

  /// MÉTODO PRIVADO: Envia a pontuação para a API com a AÇÃO (adicionar/remover).
  Future<void> _updateScoreOnBackend({
    required int points,
    required String action, // 'adicionar' ou 'remover'
  }) async {
    final user = UserHelper().user;
    if (user?.idPlano == 1 || user?.id == null) {
      log('Usuário do plano gratuito ou não autenticado. Pontuação não será enviada.');
      return;
    }
    
    // CORRIGIDO: Agora passa o 'action' para o ApiService
    await _apiService.updateRankingScore(
        userId: user!.id!, 
        points: points, 
        action: action, // <-- O novo parâmetro!
    );
  }


  // ==========================================================
  // NOVAS FUNÇÕES: LÓGICA DE PONTUAÇÃO INCREMENTAL
  // ==========================================================

  /// Adiciona pontuação para um álbum.
  Future<void> addAlbumPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      // 1. Envia a quantidade de pontos a SER ADICIONADA
      await _updateScoreOnBackend(points: pointsPerAlbum, action: 'adicionar');

      log('[Ranking Increment] Pedido para adicionar $pointsPerAlbum pontos por álbum enviado.');
      
      // NOTA: É IDEAL QUE A API RETORNE A NOVA PONTUAÇÃO.
      // Se a API retornar a nova pontuação, você deve usá-la aqui:
      // await UserHelper().updateUserScore(pontuacao_retornada);
      // Por enquanto, mantenho a lógica anterior para não quebrar o código:
      final int newScore = (user.score ?? 0) + pointsPerAlbum;
      await UserHelper().updateUserScore(newScore);

    } catch (e) {
      log('Falha ao adicionar pontos por álbum: $e');
    }
  }

  /// Adiciona pontuação para um subálbum.
  Future<void> addSubAlbumPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      await _updateScoreOnBackend(points: pointsPerSubAlbum, action: 'adicionar');

      log('[Ranking Increment] Pedido para adicionar $pointsPerSubAlbum pontos por subálbum enviado.');
      
      final int newScore = (user.score ?? 0) + pointsPerSubAlbum;
      await UserHelper().updateUserScore(newScore);

    } catch (e) {
      log('Falha ao adicionar pontos por subálbum: $e');
    }
  }

  /// Adiciona pontuação para uma tags.
  Future<void> addPhotoWithTagPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      await _updateScoreOnBackend(points: pointsPerPhotoWithTag, action: 'adicionar');
      
      log('[Ranking Increment] Pedido para adicionar $pointsPerPhotoWithTag pontos por foto com tag enviado.');
      
      final int newScore = (user.score ?? 0) + pointsPerPhotoWithTag;
      await UserHelper().updateUserScore(newScore);

    } catch (e) {
      log('Falha ao adicionar pontos por foto com tag: $e');
    }
  }

    /// Adiciona pontuação para uma foto.
  Future<void> addPhotoPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      await _updateScoreOnBackend(points: pointsPhoto, action: 'adicionar');
      
      log('[Ranking Increment] Pedido para adicionar $pointsPhoto pontos por foto com tag enviado.');
      
      final int newScore = (user.score ?? 0) + pointsPhoto;
      await UserHelper().updateUserScore(newScore);

    } catch (e) {
      log('Falha ao adicionar pontos por foto com tag: $e');
    }
  }

      /// Adiciona pontuação para uma foto.
  Future<void> addPhotoCompartilhar() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      await _updateScoreOnBackend(points: pointsPhotoCompatilhar, action: 'adicionar');
      
      log('[Ranking Increment] Pedido para adicionar $pointsPhotoCompatilhar pontos por foto com tag enviado.');
      
      final int newScore = (user.score ?? 0) + pointsPhotoCompatilhar;
      await UserHelper().updateUserScore(newScore);

    } catch (e) {
      log('Falha ao adicionar pontos por foto com tag: $e');
    }
  }



    ///FUNÇÕES PARA SUBTRAIR OS PONTOS

  /// Subtrai pontuação quando um álbum é removido.
  Future<void> removeAlbumPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      // 1. Envia a quantidade de pontos a SER REMOVIDA
      await _updateScoreOnBackend(points: pointsPerAlbum, action: 'remover');

      log('[Ranking Decrement] Pedido para remover $pointsPerAlbum pontos por álbum enviado.');

      // O frontend continua atualizando o score local (com verificação de mínimo 0)
      final int newScore = (user.score ?? 0) - pointsPerAlbum;
      final int finalScore = newScore < 0 ? 0 : newScore; 
      await UserHelper().updateUserScore(finalScore);
      
    } catch (e) {
      log('Falha ao remover pontos por álbum: $e');
    }
  }



  /// Subtrai pontuação quando um subálbum é removido.
  Future<void> removeSubAlbumPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      await _updateScoreOnBackend(points: pointsPerSubAlbum, action: 'remover');

      log('[Ranking Decrement] Pedido para remover $pointsPerSubAlbum pontos por subálbum enviado.');
      
      final int newScore = (user.score ?? 0) - pointsPerSubAlbum;
      final int finalScore = newScore < 0 ? 0 : newScore;
      await UserHelper().updateUserScore(finalScore);
      
    } catch (e) {
      log('Falha ao remover pontos por subálbum: $e');
    }
  }

  /// Subtrai pontuação quando uma foto com tags é removida.
  Future<void> removePhotoWithTagPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      await _updateScoreOnBackend(points: pointsPerPhotoWithTag, action: 'remover');
      
      log('[Ranking Decrement] Pedido para remover $pointsPerPhotoWithTag pontos por foto com tag enviado.');
      
      final int newScore = (user.score ?? 0) - pointsPerPhotoWithTag;
      final int finalScore = newScore < 0 ? 0 : newScore;
      await UserHelper().updateUserScore(finalScore);

    } catch (e) {
      log('Falha ao remover pontos por foto com tag: $e');
    }
  }


  /// Calcula a pontuação TOTAL baseada no estado atual do usuário e envia para a API.
  /// (Uso recomendado: para inicialização ou auditoria, NÃO para cada ação)
  ///
  /// NOTA: Esta função não usa os novos campos 'adicionar'/'remover'.
  /// Ela envia a pontuação TOTAL. Se o backend não aceita mais a pontuação TOTAL
  /// sem uma ação, esta função precisará ser ajustada ou removida.
  Future<void> recalculateAndUpdateScore() async {
    log('[Ranking Debug] --- INÍCIO DO RECÁLCULO DETALHADO ---');
    try {
      // ... (Resto da lógica de cálculo de pontuação total é mantida) ...

      // 4. Soma tudo para obter a pontuação final
      // ... (Lógica de cálculo de 'totalPoints' aqui) ...
      final int totalPoints = 0; // Substitua por seu cálculo real

      // 5. Envia a pontuação total e final para a API (USANDO O MÉTODO ANTIGO).
      // Se o backend NÃO ACEITA mais a pontuação total, esta linha dará erro!
      // Se precisar, o backend deve ter um endpoint específico para "SETAR" a pontuação.
      // await _apiService.updateRankingScore(userId: user!.id!, points: totalPoints); 
      // log('[Ranking Debug] PONTUAÇÃO TOTAL ENVIADA: $totalPoints pontos.');
      
      await UserHelper().updateUserScore(totalPoints); // Atualiza o local.
      log('[Ranking Debug] --- FIM DO RECÁLCULO ---');

    } catch (e) {
      log('Falha ao recalcular e enviar a pontuação: $e');
    }
  }
}

// O modelo de dados (coloque em um arquivo separado se desejar)
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
      nome: map['nome'] ?? 'Usuário anônimo',
      pontos: map['pontos']?.toString() ?? '0',
    );
  }
}