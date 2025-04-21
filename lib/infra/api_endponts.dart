class ApiEndponts {
  static const baseUrl = 'https://api.comppare.com.br/api';

  static getPlanById(int id) {
    return '$baseUrl/planos/recuperar/$id';
  }

  static get createSignature => '$baseUrl/vendas/criar-assinatura';
  static get rankingClassification => '$baseUrl/ranking/classificacao';
}
