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
  static const int pointsPerAlbum = 2;
  static const int pointsPerSubAlbum = 1;
  static const int pointsPerPhotoWithTag = 2;

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

  /// MÉTODO PRIVADO: Envia a pontuação total para a API.
  Future<void> _sendDataRanking({required int points}) async {
    final user = UserHelper().user;
    if (user?.idPlano == 1 || user?.id == null) {
      log('Usuário do plano gratuito ou não autenticado. Pontuação não será enviada.');
      return;
    }
    await _apiService.updateRankingScore(userId: user!.id!, points: points);
  }

  // ==========================================================
  // NOVAS FUNÇÕES: LÓGICA DE PONTUAÇÃO INCREMENTAL
  // ==========================================================

/// Adiciona pontuação para um álbum.
Future<void> addAlbumPoints() async {
  final user = UserHelper().user;
  if (user == null || user.idPlano == 1) return;
  try {
    final int newScore = (user.score ?? 0) + pointsPerAlbum;
    
    // 1. Envia a nova pontuação para a API
    await _sendDataRanking(points: newScore);

    // 2. Atualiza o score localmente no UserHelper
    await UserHelper().updateUserScore(newScore);

    log('[Ranking Increment] Pontos adicionados por álbum. Nova pontuação: $newScore');
  } catch (e) {
    log('Falha ao adicionar pontos por álbum: $e');
  }
}

  /// Adiciona pontuação para um subálbum.
  Future<void> addSubAlbumPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      final int newScore = (user.score ?? 0) + pointsPerSubAlbum;
      await _sendDataRanking(points: newScore);
      log('[Ranking Increment] Pontos adicionados por subálbum. Nova pontuação: $newScore');
      
      // 2. Atualiza o score localmente no UserHelper
      await UserHelper().updateUserScore(newScore);
    
    } catch (e) {
      log('Falha ao adicionar pontos por subálbum: $e');
    }
  }

  /// Adiciona pontuação para uma foto com tags.
  Future<void> addPhotoWithTagPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      final int newScore = (user.score ?? 0) + pointsPerPhotoWithTag;
      await _sendDataRanking(points: newScore);
      log('[Ranking Increment] Pontos adicionados por foto com tag. Nova pontuação: $newScore');

      // 2. Atualiza o score localmente no UserHelper
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
      final int newScore = (user.score ?? 0) - pointsPerAlbum;
      // Garante que a pontuação não seja negativa.
      final int finalScore = newScore < 0 ? 0 : newScore; 
      
      await _sendDataRanking(points: finalScore);
      await UserHelper().updateUserScore(finalScore);

      log('[Ranking Decrement] Pontos removidos por álbum. Nova pontuação: $finalScore');
    } catch (e) {
      log('Falha ao remover pontos por álbum: $e');
    }
  }

  /// Subtrai pontuação quando um subálbum é removido.
  Future<void> removeSubAlbumPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      final int newScore = (user.score ?? 0) - pointsPerSubAlbum;
      final int finalScore = newScore < 0 ? 0 : newScore;
      
      await _sendDataRanking(points: finalScore);
      await UserHelper().updateUserScore(finalScore);

      log('[Ranking Decrement] Pontos removidos por subálbum. Nova pontuação: $finalScore');
    } catch (e) {
      log('Falha ao remover pontos por subálbum: $e');
    }
  }

  /// Subtrai pontuação quando uma foto com tags é removida.
  Future<void> removePhotoWithTagPoints() async {
    final user = UserHelper().user;
    if (user == null || user.idPlano == 1) return;
    try {
      final int newScore = (user.score ?? 0) - pointsPerPhotoWithTag;
      final int finalScore = newScore < 0 ? 0 : newScore;
      
      await _sendDataRanking(points: finalScore);
      await UserHelper().updateUserScore(finalScore);

      log('[Ranking Decrement] Pontos removidos por foto com tag. Nova pontuação: $finalScore');
    } catch (e) {
      log('Falha ao remover pontos por foto com tag: $e');
    }
  }

    /// Calcula a pontuação TOTAL baseada no estado atual do usuário e envia para o ranking.
    Future<void> recalculateAndUpdateScore() async {
      log('[Ranking Debug] --- INÍCIO DO RECÁLCULO DETALHADO ---');
      try {
        // 1. Busca todos os dados mais recentes do usuário
        final List<Folder> allFolders = await _apiService.getAllFoldersForUser();
        log('[Ranking Debug] Álbuns principais encontrados: ${allFolders.length}');

        // 2. Zera os contadores
        int totalSubFolders = 0;
        int totalPhotosWithTags = 0;

        // Itera para contar os itens internos
        for (final folder in allFolders) {
          log('[Ranking Debug] Verificando álbum: "${folder.nome}" (ID: ${folder.id})');
          final subs = folder.subpastas ?? [];
          totalSubFolders += subs.length;
          log('[Ranking Debug] -> Encontrado(s) ${subs.length} subálbun(s) neste álbum.');

          for (final subfolder in subs) {
            if (subfolder.imagens != null) {
              int photosInThisSubfolder = 0;
              for (final imagem in subfolder.imagens!) {
                if (imagem.metadata != null && imagem.metadata!.isNotEmpty) {
                  totalPhotosWithTags++;
                  photosInThisSubfolder++;
                }
              }
              if (photosInThisSubfolder > 0) {
                log('[Ranking Debug] ---> Encontrada(s) $photosInThisSubfolder foto(s) com tags no subálbum "${subfolder.nome}".');
              }
            }
          }
        }

        // 3. Calcula os pontos com base na contagem
        int albumPoints = allFolders.length * pointsPerAlbum;
        int subAlbumPoints = totalSubFolders * pointsPerSubAlbum;
        int photoWithTagPoints = totalPhotosWithTags * pointsPerPhotoWithTag;

        log('[Ranking Debug] ---------------------------------------------');
        log('[Ranking Debug] CÁLCULO FINAL:');
        log('[Ranking Debug] Pontos de Álbuns: $albumPoints (${allFolders.length} x $pointsPerAlbum)');
        log('[Ranking Debug] Pontos de Subálbuns: $subAlbumPoints ($totalSubFolders x $pointsPerSubAlbum)');
        log('[Ranking Debug] Pontos de Fotos com Tags: $photoWithTagPoints ($totalPhotosWithTags x $pointsPerPhotoWithTag)');
        log('[Ranking Debug] ---------------------------------------------');

        // 4. Soma tudo para obter a pontuação final
        final int totalPoints = albumPoints + subAlbumPoints + photoWithTagPoints;

        // 5. Envia a pontuação total e final para a API
        await _sendDataRanking(points: totalPoints);
        log('[Ranking Debug] PONTUAÇÃO TOTAL ENVIADA: $totalPoints pontos.');
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