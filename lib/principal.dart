import 'dart:async';
import 'dart:convert';

import 'package:application_progress/albuns_criados.dart';
import 'package:application_progress/chat_button.dart';
import 'package:application_progress/dialog_ranking.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/repositories/ranking_repository.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/main.dart' as main_app;
import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/views/plans_page.dart';
import 'package:application_progress/views/tag_page.dart';
import 'package:application_progress/views/user_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:http/http.dart' as http;
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/api_endponts.dart';
import 'models/plan_model.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  String _searchQuery = '';
  
  final TextEditingController folderNameController = TextEditingController();
  
  bool _isLoading = true;

  bool isLoadingPlans = false;
  
  int? selectedQuestionIndex;

  List<PlanModel> plans = [];
  
  bool showMonthlyPlans = true;
  
  Map<int, bool> selectedPlans = {};
  
  bool isPlansLoading = true;
  
  int? _selectedFolderId;

  final ApiService _apiService = ApiService(httpClient: http.Client());

  late PlanModel currentPlan = PlanModel.empty();

  @override
  void initState() {
  super.initState();
  
  _checkLoginStatus(); // Verifica o status de login ao iniciar
  
  _fetchPlansAsync();
  
  _buildRankingButton(context);
        
  _fetchFoldersFromApiAndRefreshState();

  List<RankingModel> _cachedRankingItems = [];
  bool _isFetchingRanking = false; 

    // DENTRO DO STATE DA SUA TELA PRINCIPAL
  Future<void> _fetchAndCacheRanking() async {
    if (_isFetchingRanking) return;

    // Não precisamos de setState aqui, pois a função _showRankingDialog já lida com o loading visual.
    _isFetchingRanking = true;

    try {
      // 1. Busca os dados mais recentes do repositório.
      List<RankingItemModel> fetchedItems = await RankingRepository.instance.getDataRanking();
      
      // Adicione um print para debug, para ter certeza que a API está retornando dados.
      print('DEBUG: Ranking recebido da API: ${fetchedItems.length} usuários.');

      // 2. CORREÇÃO: Loop para atribuir as posições corretas a cada item.
      List<RankingItemModel> positionedItems = [];
      for (int i = 0; i < fetchedItems.length; i++) {
        positionedItems.add(RankingItemModel(
          position: i + 1,
          nome: fetchedItems[i].nome,
          pontos: fetchedItems[i].pontos,
          // Garanta que todos os outros campos do seu RankingItemModel sejam copiados aqui
        ));
      }
      
      // 3. Atualiza o cache com a lista correta e processada.
      if (mounted) {
        setState(() {
          _cachedRankingItems = positionedItems.cast<RankingModel>();
        });
      }
    } catch (e) {
      print("Erro ao buscar ranking para o cache: $e");
    } finally {
      if (mounted) {
        _isFetchingRanking = false;
      }
    }
  }
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _fetchFoldersFromApiAndRefreshState();
    }
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await TokenHelper().init(); // Inicializa o TokenHelper
      await UserHelper().init(); // Inicializa o UserHelper

      final token = TokenHelper().token;
      final user = UserHelper().user;

      if (token != null && token.isNotEmpty && user != null) {
        // Token e usuário válidos, restaura o estado
        await _apiService.refreshTokenIfNeeded(); // Renova token se necessário
        if (user.pastas?.isNotEmpty ?? false) {
          setState(() {
            UserHelper().user!.pastas = user.pastas ?? [];
            _selectedFolderId = user.pastas!.first.id;
          });
        }
        await _fetchFoldersFromApiAndRefreshState(); // Sincroniza com a API
      } else {
        // Nenhum token ou usuário, redireciona para login
        _navigateToLogin();
      }
    } catch (e) {
      foundation.debugPrint('Erro ao verificar status de login: $e');
      _navigateToLogin();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _selectFolder(int folderId) {
    setState(() {
      _selectedFolderId = folderId;
    });
  }

  Future<void> _fetchPlansAsync() async {
    setState(() {
      isPlansLoading = true;
    });
    try {
      await fetchPlans();
    } finally {
      setState(() {
        isPlansLoading = false;
      });
    }
  }

  Future<void> fetchPlans() async {
    setState(() {
      isLoadingPlans = true;
    });
    try {
      final response =
          await http.get(Uri.parse("${ApiEndpoints.baseUrl}/planos/listar"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> planosJson = data['data'];
        setState(() {
          plans = planosJson.map((json) => PlanModel.fromJson(json)).toList();
          selectedPlans = {for (var plan in plans) plan.id: false};
        });

        currentPlan = UserHelper().user?.idPlano != null
            ? plans.firstWhere((p) => p.id == UserHelper().user!.idPlano,
                orElse: () => plans.first)
            : plans.first;
      } else {
        foundation
            .debugPrint("Erro ao buscar planos: ${response.reasonPhrase}");
      }
    } catch (e) {
      foundation.debugPrint("Erro ao buscar planos: $e");
    } finally {
      setState(() {
        isLoadingPlans = false;
      });
    }
  }

  void _navigateToSubscription() {
    if (plans.isEmpty) {
      foundation
          .debugPrint('Nenhum plano disponível. Tente novamente mais tarde.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SubscriptionPage(
              initialPlan: currentPlan, availablePlans: plans)),
    );
  }



  // --- FUNÇÃO DE ATUALIZAÇÃO DE ESTADO ---
  // Esta é a nova função que você deve ter. Ela substitui a sua '_addFolder' antiga.
  Future<void> _addFolderAndUpdateState(String folderName) async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      _showErrorDialog('Usuário não autenticado.');
      _navigateToLogin();
      return;
    }

    try {
      final Map<String, dynamic> response = await _apiService.createFolder(
        idUsuario: user.id!,
        folderName: folderName.trim(),
      );

      final newFolder = Folder(
        id: response['pasta_id'] as int,
        nome: response['pasta_nome'] as String,
        caminho: response['pasta_caminho'] as String,
        principalPageDisplayName: response['estrutura_completa'] as String,
      );
      UserHelper().user?.pastas!.add(newFolder);
        Future.delayed(const Duration(seconds: 2));
        RankingRepository.instance.addEventPoints(2, contextId: '$newFolder');
      
      setState(() {});
      
      // showSuccessSnackBar(context, 'Álbum "$folderName" criado com sucesso!');

    } catch (e) {
      foundation.debugPrint('Erro ao criar álbum: $e');
      _showErrorDialog('Erro ao criar álbum.');
    }
  }



Future<void> _fetchFoldersFromApiAndRefreshState() async {
  if (!mounted) return;
  setState(() {
    _isLoading = true;
  });

  try {
    // 1. Esta linha é a mais importante: ela busca os dados mais recentes
    //    e já atualiza o nosso UserHelper.
    await _apiService.refreshUserData();

    // 2. Após a atualização, a lista de pastas mais recente já está no UserHelper.
    //    Basta chamar setState para que a UI se redesenhe com esses novos dados.
    if (mounted) {
      setState(() {
        // A linha `_folders = updatedFolders;` foi REMOVIDA, pois `_folders` não existe mais.
        
        // A lógica para selecionar o primeiro item da lista foi mantida,
        // mas agora ela lê a lista direto do UserHelper.
        final user = UserHelper().user;
        final List<Folder> updatedFolders = user?.pastas ?? [];

        if (updatedFolders.isNotEmpty && _selectedFolderId == null) {
          _selectedFolderId = updatedFolders.first.id;
        }
      });
    }
  } catch (e) {
    //... seu tratamento de erro
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  Future<void> _confirmAndDeleteFolder(Folder folder) async {
    final user = UserHelper().user;
    if (user == null || user.id == null || !TokenHelper().hasToken()) {
      _navigateToLogin();
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
                // 1. Verificação principal do estado de carregamento
          if (_isLoading) {
            // Se estiver carregando, mostra uma tela de loading simples e centralizada.
            // O Scaffold é importante para dar um fundo branco padrão.
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFaed513), // Usando a cor primária do seu app
                ),
              ),
            );
          }

        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
              'Tem certeza que deseja excluir o álbum "${folder.principalPageDisplayName}"? Esta ação removerá todas as imagens e informações inseridas e não poderá ser desfeita.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.deleteFolder(user.id!, folder.id);
        await Future.delayed(const Duration(seconds: 2));
        print('Álbum ${folder.id} deletado no app. Iniciando recálculo...');
        await RankingRepository.instance.recalculateAndUpdateScore(); // Atualiza a pontuação

        if (mounted) {
          // 1. Remove o álbum DIRETAMENTE da fonte da verdade.
          UserHelper().user?.pastas!.removeWhere((f) => f.id == folder.id);
          
          setState(() {});
         // showSuccessSnackBar(context, 'Album "${folder.principalPageDisplayName}" excluída com sucesso!');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Album "${folder.principalPageDisplayName}" excluído com sucesso!')),
          );
          
          
        }
      } on ApiException catch (e) {
        foundation.debugPrint('Erro em _confirmAndDeleteFolder: ${e.message}');
        if (mounted) {
          _showErrorDialog('Não foi possível excluir o Album: ${e.message}');
          if (e.statusCode == 401) {
            _navigateToLogin();
          }
        }
      } catch (e) {
        foundation.debugPrint('Erro inesperado em _confirmAndDeleteFolder: $e');
        if (mounted) {
          _showErrorDialog('Ocorreu um erro inesperado ao excluir o Album.');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Erro'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _navigateToLogin() {
    if (!mounted) return;
    TokenHelper().clear();
    UserHelper().removeUser();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _showAModal() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isDialogLoading = false;
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  minWidth: 320,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFaed513).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFaed513)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              color: Color(0xFFaed513),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Criar Novo Álbum',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Dê um nome para seu álbum',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: folderNameController,
                          enabled: !isDialogLoading,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: Minhas Férias 2024',
                            hintStyle: TextStyle(
                              color: Colors.black.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.folder,
                              color: Colors.black.withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ),
                          onSubmitted: (value) async {
                            if (!isDialogLoading && value.trim().isNotEmpty) {
                              await _handleCreateAlbum(setDialogState,
                                  dialogContext, isDialogLoading);
                            }
                          },
                        ),
                      ),
                      // ignore: dead_code
                      if (isDialogLoading) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFaed513)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Criando álbum...',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isDialogLoading
                                  ? null
                                  : () {
                                      folderNameController.clear();
                                      Navigator.of(dialogContext).pop();
                                    },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isDialogLoading
                                  ? null
                                  : () async {
                                      await _handleCreateAlbum(setDialogState,
                                          dialogContext, isDialogLoading);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFaed513),
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isDialogLoading ? 'Criando...' : 'Criar Álbum',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- FUNÇÃO ATUALIZADA ---
  // Agora ela chama a nova função _addFolderAndUpdateState.
  Future<void> _handleCreateAlbum(Function setDialogState,
        BuildContext dialogContext, bool isDialogLoading) async {
      String folderName = folderNameController.text.trim();
      if (folderName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, insira um nome para o álbum.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setDialogState(() {
        isDialogLoading = true;
      });

      try {
        // Chama a nova função que já cuida da API e do setState
        await _addFolderAndUpdateState(folderName);

        if (context.mounted) {
          Navigator.of(dialogContext).pop();
          folderNameController.clear();
        }
      } catch (e) {
        foundation.debugPrint('Erro no modal de criar álbum: $e');
        if (context.mounted) {
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar álbum: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

  Widget _buildHeaderSection() {
    return GestureDetector(
      onTap: _showAModal,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFaed513).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFaed513).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFaed513),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFaed513).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showAModal,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Criar Novo Álbum',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Organize suas fotos em álbuns personalizados',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Buscar álbuns...',
              hintStyle: TextStyle(
                color: Colors.black.withValues(alpha: 0.5),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black.withValues(alpha: 0.7),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsSection() {
    return Expanded(
      child: UserHelper().user!.pastas!.isEmpty && !_isLoading
          ? _buildEmptyState()
          : _buildAlbumsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum álbum encontrado',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.8),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro álbum para começar\na organizar suas fotos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsList() {
    final filteredFolders = UserHelper().user!.pastas!.where((folder) {
      if (_searchQuery.isEmpty) return true;
      return folder.pageDisplayName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchFoldersFromApiAndRefreshState,
      color: const Color(0xFFaed513),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: filteredFolders.length,
        itemBuilder: (context, index) {
          final folder = filteredFolders[index];
          return _buildAlbumCard(folder);
        },
      ),
    );
  }

  Widget _buildAlbumCard(Folder folder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbunsCriadosPage(
                  initialFolderName: folder.pageDisplayName,
                  initialFolderId: folder.id,
                  folderApiPath: folder.caminho,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFaed513).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder,
                    color: Color(0xFFaed513),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.pageDisplayName.isNotEmpty
                            ? folder.pageDisplayName
                            : 'Album sem nome',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clique para visualizar',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmAndDeleteFolder(folder),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  tooltip: 'Excluir álbum',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.black,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }

  // Novo design  para as mesnsagens 
 /* void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  // Exibe a nova SnackBar com um estilo mais elaborado.
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFaed513), // Um tom de verde mais escuro e sólido
      behavior: SnackBarBehavior.floating, // Estilo flutuante que combina com a UI
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.all(16.0),
      duration: const Duration(seconds: 4), // Tempo que a notificação fica visível
      elevation: 6.0,
    ),
  );
}*/

/// Constrói o botão de acesso ao Ranking, que se adapta ao plano do usuário.
Widget _buildRankingButton(BuildContext context) {
  // 1. Verifica o plano do usuário ANTES de construir o botão.
  // Ajuste esta linha se o seu ID de plano gratuito for diferente.
  final userPlanId = UserHelper().user?.idPlano ?? 1;
  
  final bool isFreePlan = (userPlanId == 1);

  // Define a cor do texto com base no plano.
  final Color textColor = isFreePlan ? Colors.grey.shade600 : Colors.black;

  return InkWell(
    // 2. Ação de clique condicional.
    onTap: () {
      if (isFreePlan) {
        // Se for gratuito, mostra uma mensagem rápida em vez de abrir o diálogo.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este é um recurso para assinantes. Faça um upgrade!'),
            backgroundColor: Colors.amber,
          ),
        );
      } else {
        // Se for premium, chama a função que busca os dados e abre o diálogo.
        _showRankingDialog(context, currentPlan, plans);
      }
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isFreePlan ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3. Ícone e Texto
          Column(
            children: [
              Icon(Icons.leaderboard, color: textColor, size: 30),
              const SizedBox(height: 8),
              Text(
                'Ranking',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          // 4. Cadeado (só aparece se for plano gratuito)
          if (isFreePlan)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)
              ),
              child: const Center(
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ESTA É A NOVA FUNÇÃO INTELIGENTE QUE VOCÊ DEVE ADICIONAR NA SUA TELA
Future<void> _showRankingDialog(
  BuildContext context,
  PlanModel currentPlan,
  List<PlanModel> allPlans,
) async {
  // Mostra um loading na tela principal
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final user = UserHelper().user;
    // 1. Pega o id do plano, que pode ser nulo. Não atribuímos um valor padrão aqui.
    final int? userPlanId = user?.idPlano;

    // --- CORREÇÃO PRINCIPAL ---
    // 2. A verificação agora bloqueia se o plano for NULO ou se for o plano gratuito (ID 1).
    const ID_PLANO_GRATUITO = 1;
    final bool isBlocked = (userPlanId == null || userPlanId == ID_PLANO_GRATUITO);

    RankingModel rankingData;

    if (isBlocked) {
      // Se for bloqueado, prepara os dados para a mensagem de upgrade
      rankingData = RankingModel(
        // Passamos o userPlanId (que pode ser 1 ou null)
        userPlanId: userPlanId,
        items: [],
        currentPlan: currentPlan,
        allPlans: allPlans,
      );
    } else {
      // Se não for bloqueado, busca os dados do ranking
      final fetchedItems = await RankingRepository.instance.getDataRanking();

      // Atribui as posições
      for (int i = 0; i < fetchedItems.length; i++) {
        fetchedItems[i] = RankingItemModel(
          position: i + 1,
          nome: fetchedItems[i].nome,
          pontos: fetchedItems[i].pontos,
        );
      }
      
      rankingData = RankingModel(
        userPlanId: userPlanId,
        items: fetchedItems,
        currentPlan: PlanModel.empty(),
        allPlans: [],
      );
    }

    // Fecha o dialog de loading
    if (context.mounted) Navigator.of(context).pop();

    // Abre o DialogRanking final com os dados corretos
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => DialogRanking(data: rankingData),
      );
    }
  } catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    print("Erro ao preparar ranking: $e");
    // Opcional: Mostrar um SnackBar de erro para o usuário
  }
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

        // 1. Verificação principal do estado de carregamento
    if (_isLoading) {
      // Se estiver carregando, mostra uma tela de loading simples e centralizada.
      // O Scaffold é importante para dar um fundo branco padrão.
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFaed513), // Usando a cor primária do seu app
          ),
        ),
      );
    }
    
    // A lista de álbuns para exibição vem DIRETAMENTE da fonte da verdade.
    final List<Folder> foldersToDisplay = UserHelper().user?.pastas ?? [];

    return Scaffold(
      floatingActionButton: const ChatButton(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PrincipalPage()),
              (Route<dynamic> route) => false,
            );
          },
          child: Center(
            child: Image.asset(
              "assets/logo_cortada.png",
              width: isLargeScreen ? screenWidth * 0.3 : screenWidth * 0.4,
              height: isLargeScreen ? screenHeight * 0.05 : screenHeight * 0.07,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black, size: 24),
            onPressed: () async {
              await TokenHelper().clear();
              await UserHelper().removeUser();
              _navigateToLogin();
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFaed513),
                strokeWidth: 3,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 32),
                    _buildSearchSection(),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Álbuns Criados',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAlbumsSection(),
                  ],
                ),
              ),
            ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFaed513),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20).copyWith(bottom: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      UserHelper().user?.nome ?? 'Convidado',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bem-vindo de volta!',
                                      style: TextStyle(
                                        color:
                                            Colors.black.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        //   margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFaed513),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              currentPlan.nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Perfil',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) =>
                              UserDashboardScreen(folders: foldersToDisplay,), // <-- CORRIGIDO: Passando a lista de Albuns
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.leaderboard,
                      title: 'Ranking',
                      onTap: () {
                        Navigator.pop(context);
                        _showRankingDialog(context, currentPlan, plans);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.assignment,
                      title: 'Planos',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToSubscription();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.tag,
                      title: 'Categorias',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateTagsPage()),
                        );
                      },
                    ),
                    Divider(color: Colors.grey[400]),
                    _buildDrawerItem(
                      icon: Icons.exit_to_app,
                      title: 'Sair',
                      onTap: () async {
                        await TokenHelper().clear();
                        await UserHelper().removeUser();
                        _navigateToLogin();
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
