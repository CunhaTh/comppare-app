import 'dart:developer';

/// Uma classe estática para gerenciar todos os endpoints da API.
/// Centraliza as URLs para facilitar a manutenção e evitar erros de digitação.
class ApiEndpoints {
  // Pega a URL da variável de ambiente ou usa a padrão
  static String get baseUrl {
    const apiEndpoint = String.fromEnvironment('API_ENDPOINT');
    log('API_ENDPOINT: $apiEndpoint');
    return apiEndpoint.isNotEmpty
        ? apiEndpoint
        : 'https://api.comppare.com.br/api';
  }

  static const String recoverFolder =
      '/pasta/recuperar'; // Remover '/api' daqui

  /// Endpoint para criar uma assinatura de vendas (admin).
  static String get createSignature => '$baseUrl/admin/vendas/criar-assinatura';

  /// Endpoint para obter a classificação do ranking de usuários.
  static String get rankingClassification =>
      '$baseUrl/usuarios/ranking/classificacao';

  /// Endpoint para atualizar o ranking (admin).
  static String get updateRanking => '$baseUrl/admin/ranking/atualizar';

  /// Endpoint para listar questões do chat.
  static String get getChatQuestions => '$baseUrl/questoes/listar';

  /// Endpoint para enviar (salvar) uma questão do chat.
  static String get sendChatQuestion => '$baseUrl/questoes/salvar';

  /// Endpoint para verificar e atualizar o plano do usuário.
  static String get checkUpdatePlan => '$baseUrl/usuarios/atualizar-plano';

  /// Endpoint para listar todos os planos disponíveis.
  static String get getPlans => '$baseUrl/planos/listar';

  // --- Endpoints de Autenticação e Criação de Pastas ---
  /// Endpoint para autenticar o usuário.
  static String get authenticateUser => '$baseUrl/usuarios/autenticar';

  /// Endpoint para criar uma nova pasta.
  // POST: { "idUsuario": ..., "nomePasta": ..., "parentFolderId": ..., "tags": [...] }
  static String get createFolder => '$baseUrl/pasta/create';
 
  //Endpoint para criar subalbuns
  static String get createSubFolder => '$baseUrl/pasta/create';

  /// Endpoint para excluir uma pasta.
  /// Usa o método DELETE na API, enviando o folderId no corpo.
  // DELETE: { "folderId": ... }
  static String get deleteFolder => '$baseUrl/pasta/excluir';

  /// lista o valor das tags.
  static String get listarTags => '$baseUrl/tags/recuperar-tags-usuario';

  /// Endpoint para excluir uma imagem específica.
  /// Usa o método DELETE na API.
  static String get deleteImage => '$baseUrl/imagens/excluir';

  /// Endpoint para fazer upload de imagens.
  /// Formato esperado: POST /api/imagens/salvar (com idUsuario e idPasta como campos no multipart)
  static String get uploadImages => '$baseUrl/imagens/salvar';


  // Salva as tags
  static String get cadastraTags => '$baseUrl/tags/cadastrar';

  
  // exclui as tags
  static String get excluiTags => '$baseUrl/tags/excluir';
  
  
  // salva valor de cada imagem
  static String get salvaComparacao => '$baseUrl/comparacao/salvar';

  // recupera as
    static String getComparacao(int idPhoto) {
    return '$baseUrl/comparacao$idPhoto';
  }

  // --- Endpoints de Pastas e Conteúdo ---

  // O endpoint listAllUserFolders foi removido, pois as pastas agora vêm da autenticação.

  /// ENDPOINT EXISTENTE: Para recuperar os detalhes de UMA pasta específica pelo ID.
  /// Este endpoint é o que você usou no Insomnia e retorna uma pasta com suas imagens.
  /// Será usado na `AlbunsCriadosPage` para obter o conteúdo de uma pasta específica.
  static String getFolderDetails(int idFolder) {
    return '$baseUrl/pasta/recuperar?idPasta=$idFolder';
  }
}
