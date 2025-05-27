class ApiEndpoints {
  static const baseUrl = 'https://api.comppare.com.br/api';

  static getPlanById(int id) {
    return '$baseUrl/planos/recuperar/$id';
  }

  static String get createSignature => '$baseUrl/admin/vendas/criar-assinatura';
  static String get rankingClassification =>
      '$baseUrl/usuarios/ranking/classificacao';
  static String get updateRanking => '$baseUrl/admin/ranking/atualizar';
  static String get getChatQuestions => '$baseUrl/questoes/listar';
  static String get sendChatQuestion => '$baseUrl/questoes/salvar';
  static String get checkUpdatePlan => '$baseUrl/usuarios/atualizar-plano';
}
