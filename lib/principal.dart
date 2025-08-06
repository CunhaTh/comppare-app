// lib/principal.dart

import 'dart:async';
import 'dart:convert';

import 'package:application_progress/albuns_criados.dart'; // Importa a AlbunsCriadosPage
import 'package:application_progress/chat_button.dart';
import 'package:application_progress/dialog_ranking.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';

// IMPORTAÇÕES CORRETAS DOS MODELOS
import 'package:application_progress/models/folder_model.dart'; // Para o modelo Folder
import 'package:application_progress/views/plans_page.dart';
import 'package:application_progress/views/tag_page.dart';
import 'package:application_progress/views/user_dashboard.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:application_progress/infra/api_exception.dart';

import 'infra/api_endponts.dart';
import 'models/plan_model.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  List<Folder> _folders = [];
  String _searchQuery = '';
  final TextEditingController folderNameController = TextEditingController();
  bool _isLoading = true;
  int? selectedQuestionIndex;
  bool isLoading = false; // Para outras operações, se aplicável
  List<PlanModel> plans = [];
  bool showMonthlyPlans = true;
  Map<int, bool> selectedPlans = {};
  bool isPlansLoading = true; // Novo estado para carregamento de planos

  final ApiService _apiService = ApiService(httpClient: http.Client());

  late PlanModel currentPlan = PlanModel.empty();

  @override
  void initState() {
    super.initState();
    _fetchPlansAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchFoldersFromApiAndRefreshState();
  }

  Future<void> _fetchPlansAsync() async {
    setState(() {
      isPlansLoading = true;
    });
    try {
      await fetchPlans(); // Aguarda a população de plans
    } finally {
      setState(() {
        isPlansLoading = false;
      });
    }
  }

  Future<void> fetchPlans() async {
    setState(() {
      isLoading = true;
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
        print("Erro ao buscar planos: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Erro ao buscar planos: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToSubscription() {
    if (plans.isEmpty) {
      print('Nenhum plano disponível. Tente novamente mais tarde.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SubscriptionPage(
              initialPlan: currentPlan, availablePlans: plans)),
    );
  }

  /*void _addTagList() {
    if (plans.isEmpty) {
      print('Nenhum plano disponível. Tente novamente mais tarde.');
      return;
    }
    final currentPlan = UserHelper().user?.idPlano != null
        ? plans.firstWhere((p) => p.id == UserHelper().user!.idPlano,
            orElse: () => plans.first)
        : plans.first;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubscriptionPage(initialPlan: plans.first, availablePlans: plans)),
    );
  }*/

  Future<void> _addFolder(String folderName) async {
    final user = UserHelper().user;
    if (user == null || user.id == null || user.nome == null) {
      debugPrint(
          '[_addFolder] Tentativa de criar pasta sem usuário ou ID válido. Usuário: $user');
      _showErrorDialog(
          'Erro: Usuário não logado ou ID de usuário inválido. Por favor, faça login novamente.');
      _navigateToLogin();
      return;
    }

    try {
      final String folderNameForApi = folderName.trim();
      debugPrint(
          '[_addFolder] Tentando criar pasta com nome: $folderNameForApi, userId: ${user.id}');

      final response = await _apiService.createFolder(
        idUsuario: user.id!,
        folderName: folderNameForApi,
        parentFolderId: null,
      );
      debugPrint(
          '[_addFolder] Resposta bruta da API: ${json.encode(response)}');
      debugPrint(
          '[_addFolder] Campos da resposta: ${response.keys.join(', ')}');
      debugPrint(
          '[_addFolder] Pasta criada com sucesso, resposta: ${json.encode(response)}');

      if (mounted) {
        // Usar diretamente os valores da resposta da API
        final folderId = response['pasta_id'] as int? ?? 0;
        final folderNameFromApi =
            response['pasta_nome'] as String? ?? folderNameForApi;
        final folderPath = response['pasta_caminho'] as String?;
        final folderType = response['tipo'] as String?;
        final folderStructure =
            response['estrutura_completa'] as String? ?? folderNameFromApi;

        final folderToAdd = Folder(
          id: folderId,
          nome: folderNameFromApi, // Prioriza o nome da API
          caminho: folderPath!,
          principalPageDisplayName:
              folderStructure, // Usa estrutura_completa para exibição
          idPastaPai: null,
          imagens: [],
          tags: [],
          subpastas: [],
        );

        // Atualiza a UI imediatamente com o novo folder
        setState(() {
          _folders.add(folderToAdd);
        });
        debugPrint(
            '[_addFolder] Folder adicionado: id=${folderToAdd.id}, nome=${folderToAdd.nome}');

        // Atualiza a lista completa para sincronizar com os dados reais
        if (mounted) {
          try {
            await _fetchFoldersFromApiAndRefreshState();
            folderNameController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Álbum "$folderName" criado com sucesso!')),
            );
            debugPrint(
                '[_addFolder] Lista atualizada com sucesso via _fetchFoldersFromApiAndRefreshState');
          } catch (e) {
            debugPrint('[_addFolder] Erro ao atualizar após criação: $e');
            if (mounted) {
              _showErrorDialog('Erro ao atualizar a lista de álbuns.');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[_addFolder] Erro ao criar álbum: $e');
      if (e is ApiException && mounted) {
        _showErrorDialog('Falha ao criar o álbum: ${e.message}');
        if (e.statusCode == 401) {
          _navigateToLogin();
        }
      }
    }
  }

  Future<void> _fetchFoldersFromApiAndRefreshState() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    debugPrint('PRINT do setState e mounted no Inicio da _fetch: $mounted');

    debugPrint(
        'PrincipalPage: Token no início de _fetchFoldersFromApiAndRefreshState: ${TokenHelper().token}');

    try {
      final user = UserHelper().user;
      if (user == null || user.id == null) {
        debugPrint('Usuário não autenticado. Redirecionando para login.');
        _navigateToLogin();
        return;
      }

      // Recarrega as pastas do UserHelper atualizado
      final List<Folder> updatedFolders =
          await _apiService.getAllFoldersForUser();
      if (mounted) {
        setState(() {
          _folders = updatedFolders;
          debugPrint('Pastas atualizadas do UserHelper: ${_folders.length}');
          debugPrint('PRINT do setState e mounted Na classe FOLDER : $mounted');
        });
      }
    } on ApiException catch (e) {
      debugPrint('Erro ao atualizar pastas da API: ${e.message}');
      if (mounted) {
        _showErrorDialog(
            'Não foi possível atualizar seus álbuns. ${e.message}');
        if (e.statusCode == 401) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      debugPrint('Erro inesperado ao atualizar pastas da API: $e');
      if (mounted) {
        _showErrorDialog(
            'Ocorreu um erro inesperado ao atualizar seus álbuns.');
      }
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
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
              'Tem certeza que deseja excluir a pasta "${folder.principalPageDisplayName}"? Esta ação removerá todas as imagens dentro dela e não poderá ser desfeita.'),
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

        if (mounted) {
          // Remove o folder da lista local imediatamente
          setState(() {
            _folders.removeWhere((f) => f.id == folder.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Pasta "${folder.principalPageDisplayName}" excluída com sucesso!')),
          );
          // Sincroniza com a API para garantir consistência
          await _fetchFoldersFromApiAndRefreshState();
        }
      } on ApiException catch (e) {
        debugPrint('Erro em _confirmAndDeleteFolder: ${e.message}');
        if (mounted) {
          _showErrorDialog('Não foi possível excluir a pasta: ${e.message}');
          if (e.statusCode == 401) {
            _navigateToLogin();
          }
        }
      } catch (e) {
        debugPrint('Erro inesperado em _confirmAndDeleteFolder: $e');
        if (mounted) {
          _showErrorDialog('Ocorreu um erro inesperado ao excluir a pasta.');
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
    TokenHelper().clearToken();
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
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isDialogLoading = false;

            return AlertDialog(
              title: const Text('Criar Novo Álbum'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: folderNameController,
                    decoration:
                        const InputDecoration(hintText: "Nome do Álbum"),
                    enabled: !isDialogLoading,
                  ),
                  if (isDialogLoading)
                    // ignore: dead_code
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  // ignore: dead_code
                  onPressed: isDialogLoading
                      ? null
                      : () {
                          folderNameController.clear();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  // ignore: dead_code
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          String folderName = folderNameController.text.trim();
                          if (folderName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Por favor, insira um nome para o álbum.')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isDialogLoading = true;
                          });

                          try {
                            await _addFolder(folderName);
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            debugPrint('Erro no modal de criar álbum: $e');
                          } finally {
                            if (context.mounted) {
                              setDialogState(() {
                                isDialogLoading = false;
                              });
                            }
                          }
                        },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Header Section - Create Album Button
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
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFaed513).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Create Album Button
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

            // Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Criar Novo Álbum',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Organize suas fotos em álbuns personalizados',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
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

  // Search Section
  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Buscar álbuns...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
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

  // Albums Section
  Widget _buildAlbumsSection() {
    return Expanded(
      child: _folders.isEmpty && !_isLoading
          ? _buildEmptyState()
          : _buildAlbumsList(),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum álbum encontrado',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro álbum para começar\na organizar suas fotos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Albums List
  Widget _buildAlbumsList() {
    final filteredFolders = _folders.where((folder) {
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

  // Album Card
  Widget _buildAlbumCard(Folder folder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
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
                // Album Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFaed513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: const Color(0xFFaed513),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Album Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.pageDisplayName.isNotEmpty
                            ? folder.pageDisplayName
                            : 'Pasta sem nome',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clique para visualizar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  onPressed: () => _confirmAndDeleteFolder(folder),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withOpacity(0.8),
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

  // Drawer Item Helper
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
          color: isDestructive ? Colors.red : Colors.white,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    return Scaffold(
      floatingActionButton: const ChatButton(),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFaed513),
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
            icon: const Icon(Icons.refresh, color: Colors.black, size: 24),
            onPressed: _fetchFoldersFromApiAndRefreshState,
            tooltip: 'Atualizar álbuns',
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
                    // Header Section
                    _buildHeaderSection(),
                    const SizedBox(height: 32),

                    // Search Section
                    _buildSearchSection(),
                    const SizedBox(height: 24),

                    const SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Álbuns Criados',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Albums Section
                    _buildAlbumsSection(),
                  ],
                ),
              ),
            ),
      drawer: Drawer(
        child: Container(
          color: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFaed513),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.1),
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
                                        color: Colors.black.withOpacity(0.7),
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
                    // Plan Badge
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: const Color(0xFFaed513),
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

              // Menu Items
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Início',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) =>
                              const UserDashboardScreen(folders: []),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.leaderboard,
                      title: 'Ranking',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => const DialogRanking(),
                        );
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
                      title: 'Tags',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateTagsPage()),
                        );
                      },
                    ),
                    const Divider(color: Colors.grey),
                    _buildDrawerItem(
                      icon: Icons.exit_to_app,
                      title: 'Sair',
                      onTap: () async {
                        await TokenHelper().clearToken();
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
