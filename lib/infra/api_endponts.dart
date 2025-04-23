class ApiEndpoints {
  static const baseUrl = 'https://api.comppare.com.br/api';

  static getPlanById(int id) {
    return '$baseUrl/planos/recuperar/$id';
  }

  static String get createSignature => '$baseUrl/vendas/criar-assinatura';
  static String get rankingClassification => '$baseUrl/ranking/classificacao';
  static String get updateRanking => '$baseUrl/ranking/atualizar';
}
