import 'dart:convert';
import 'dart:js_interop';

import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/models/image_model.dart';
import 'package:application_progress/models/tag_model.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/comppareimg.dart'
    hide FilePickerHelper;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:shared_preferences/shared_preferences.dart';

// Meus imports
import 'package:application_progress/main.dart' as main_app;
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/file_picker_helper.dart';
import 'package:flutter/material.dart' as devtools;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' hide User; 

// Função auxiliar para copiar Folder
Folder copyFolder(Folder folder, {List<String>? tags}) {
  return Folder(
    id: folder.id,
    nome: folder.nome,
    caminho: folder.caminho,
    idPastaPai: folder.idPastaPai,
    imagens: folder.imagens,
    subpastas: folder.subpastas,
    tags: tags ?? folder.tags ?? [],
  );
}

class AlbunsCriadosPage extends StatefulWidget {
  final String initialFolderName;
  final int initialFolderId;
  final String folderApiPath;

  const AlbunsCriadosPage({
    super.key,
    required this.initialFolderName,
    required this.initialFolderId,
    required this.folderApiPath,
  });

  @override
  State<AlbunsCriadosPage> createState() => _AlbunsCriadosState();
}

class _AlbunsCriadosState extends State<AlbunsCriadosPage> {
  final _subalbumNameController = TextEditingController();
  final _tagsController = TextEditingController();

  final String _searchQuery = '';
  List<Folder> _subfolders = [];
  List<String> _availableTags = [];
  List<TagModel> _tags = [];

  late Future<List<TagModel>> _tagsFuture;
  String? _selectedTag;
  bool _isLoading = true;

  final ApiService _apiService = ApiService(httpClient: http.Client());
  

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
    _fetchSubfoldersFromApiAndRefreshState();
  }

  @override
  void dispose() {
    _subalbumNameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // 1. Crie uma função unificada para carregar as tags
// Esta função irá carregar as tags do cache ou da API, garantindo que
// os dados estejam prontos antes de serem usados.
Future<List<TagModel>> loadAllTags(String userId, ApiService apiService) async {
  final prefs = await SharedPreferences.getInstance();
  final tagsKey = 'user_${userId}_tags';

  try {
    // Tenta carregar as tags da API
    final tagsFromApi = await apiService.getTags(userId as int);
    
    // Serializa e salva no cache
    final tagsJsonList = tagsFromApi.map((tag) => tag.toMap()).toList();
    await prefs.setString(tagsKey, jsonEncode(tagsJsonList));
    
    return tagsFromApi;
  } catch (e) {
    // Se a API falhar, tenta carregar do cache
    final tagsString = prefs.getString(tagsKey);
    if (tagsString != null) {
      final List<dynamic> decodedJson = jsonDecode(tagsString);
      return decodedJson.map((e) => TagModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    
    // Se o cache também estiver vazio, retorna uma lista vazia
    debugPrint('Erro: Falha ao carregar tags da API e do cache local.');
    return [];
  }
}



  Future<void> _loadAvailableTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsString = prefs.getString('global_tags');
    if (tagsString != null) {
      setState(() {
        _availableTags = (jsonDecode(tagsString) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      });
    }
  }



  // Método para recuperar tags do shared_preferences
  Future<List<String>> _loadTags(int folderId) async {
    final prefs = await SharedPreferences.getInstance();
    final tagsString = prefs.getString('tags_$folderId');
    return tagsString != null
        ? (jsonDecode(tagsString) as List<dynamic>)
            .map((t) => t.toString())
            .toList()
        : [];
  }


    // Método para salvar tags no shared_preferences
  Future<void> _saveTags(int folderId, List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tags_$folderId', jsonEncode(tags));
    debugPrint(
        'Tags salvas localmente para folderId $folderId: ${tags.join(",")}');
  }

  
  void _removeTagDaPasta(Folder folder, String tag) {
    setState(() {
      final currentTags = folder.tags ?? [];
      if (currentTags.contains(tag)) {
        folder.tags = currentTags.where((t) => t != tag).toList();
        _saveTags(folder.id, folder.tags!);
      }
    });
  }

  // Método para remover tags ao deletar subpasta
  Future<void> _removeTags(int folderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tags_$folderId');
    debugPrint('Tags removidas localmente para folderId $folderId');
  }

  // Método para remover uma tag específica
  Future<void> _removeTag(Folder folder, String tag) async {
    if (!mounted) return;
    setState(() {
      folder.tags?.remove(tag);
    });
    await _saveTags(folder.id, folder.tags ?? []);
    debugPrint('Tag "$tag" removida do folderId ${folder.id}');
  }


  void _addTagToFolder(Folder folder, String tag) {
    setState(() {
      final currentTags = folder.tags ?? [];
      if (!currentTags.contains(tag)) {
        folder.tags = [...currentTags, tag];
        _saveTags(folder.id, folder.tags!);
      }
    });
  }


  Future<void> _fetchSubfoldersFromApiAndRefreshState() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    debugPrint(
        'AlbunsCriados: Token no início de _fetchSubfoldersFromApiAndRefreshState: ${TokenHelper().token}');
    debugPrint(
        'AlbunsCriados: Buscando subálbum para initialFolderId: ${widget.initialFolderId}');

    try {
      final user = UserHelper().user;
      if (user == null || user.id == null || !TokenHelper().hasToken()) {
        debugPrint(
            'Usuário não autenticado ou token ausente. Redirecionando para login.');
        _navigateToLogin();
        return;
      }

      final List<Folder> subfolders =
          await _apiService.fetchSubfolders(widget.initialFolderId);
      debugPrint(
          'subálbum recebidos da API: ${subfolders.map((f) => 'id=${f.id}, nome=${f.nome}, idPastaPai=${f.idPastaPai}, tags=${f.tags?.join(",") ?? "nenhuma"}').join(', ')}');

      if (mounted) {
        final updatedSubfolders = await Future.wait(subfolders.map((f) async {
          final localTags = await _loadTags(f.id);
          return copyFolder(f,
              tags: localTags.isNotEmpty ? localTags : f.tags ?? []);
        }).toList());
        setState(() {
          _subfolders = updatedSubfolders;
          debugPrint('subálbum atualizados: ${_subfolders.length}');
        });
      }
    } on ApiException catch (e) {
      debugPrint('Erro ao atualizar subálbum da API: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar subálbum: ${e.message}')),
        );
        if (e.statusCode == 401) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      debugPrint('Erro inesperado ao atualizar subpastas da API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Ocorreu um erro inesperado ao carregar subálbum.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSubfolder(String subfolderName) async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      debugPrint(
          '[_addSubfolder] Tentativa de criar subpasta sem usuário ou ID válido.');
      _showErrorDialog('Erro: Usuário não logado. Faça login novamente.');
      _navigateToLogin();
      return;
    }

    try {
      final String subfolderNameForApi = subfolderName.trim();
      debugPrint(
          '[_addSubfolder] Tentando criar subálbum com nome: $subfolderNameForApi, parentFolderId: ${widget.initialFolderId}, parentFolderPath: ${widget.folderApiPath}}');

      final response = await _apiService.createSubFolder(
        parentFolderId: widget.initialFolderId,
        idUsuario: user.id!,
        folderName: subfolderNameForApi,
        parentFolderPath: widget.folderApiPath,
      );
      debugPrint(
          '[_addSubfolder] Subalbum criada com sucesso, resposta: ${json.encode(response)}');

      if (mounted) {
        final newSubfolder = Folder.fromMap({
          'id': response['id'] ?? 0,
          'nome': response['caminho'] ??
              '${response['nome'] ?? subfolderNameForApi}',
          'caminho': response['caminho'],
          'idPastaPai': widget.initialFolderId,
          'imagens': [],
          'subpastas': [],
              
        });
        setState(() {
          _subfolders.add(newSubfolder);
        });
        debugPrint(
            '[_addSubfolder] Subpasta adicionada localmente: id=${newSubfolder.id}, nome=${newSubfolder.nome}, idPastaPai=${newSubfolder.idPastaPai} ?? "nenhuma"}');
      }
    } catch (e) {
      debugPrint('[_addSubfolder] Erro ao criar subpasta: $e');
      if (e is ApiException && mounted) {
        _showErrorDialog('Falha ao criar a subpasta: ${e.message}');
        if (e.statusCode == 401) {
          _navigateToLogin();
        }
      }
    }

    if (mounted) {
      try {
        await _fetchSubfoldersFromApiAndRefreshState();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Subpasta "$subfolderName" criada com sucesso!')),
        );
      } catch (e) {
        debugPrint('[_addSubfolder] Erro ao atualizar após criação: $e');
        if (mounted) {
          _showErrorDialog('Erro ao atualizar a lista de subpastas.');
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

  void _showAddSubalbumDialog() {
    if (!mounted) return;
    _subalbumNameController.clear();
    _tagsController.clear();

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen =
        screenWidth > 520 && MediaQuery.of(context).size.height > 889;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              bool isDialogLoading = false;
              return AlertDialog(
                title: const Text('Criar Novo Subálbum'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _subalbumNameController,
                      decoration: InputDecoration(
                        hintText: 'Nome do subálbum',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen
                              ? screenWidth * 0.02
                              : screenWidth * 0.028,
                          vertical: isLargeScreen
                              ? screenWidth * 0.015
                              : screenWidth * 0.022,
                        ),
                      ),
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
                    onPressed: isDialogLoading
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    child: const Text('Salvar'),
                    onPressed: isDialogLoading
                        ? null
                        : () async {
                            final subalbumName =
                                _subalbumNameController.text.trim();
                            if (subalbumName.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'O nome do subálbum não pode ser vazio.')),
                                );
                              }
                              return;
                            }

                            final tagsString = _tagsController.text.trim();
                            final List<String> tags = tagsString.isNotEmpty
                                ? tagsString
                                    .split(',')
                                    .map((tag) => tag.trim())
                                    .where((tag) => tag.isNotEmpty)
                                    .toList()
                                : [];

                            setDialogState(() => isDialogLoading = true);
                            try {
                              await _addSubfolder(subalbumName);
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } catch (e) {
                              debugPrint('Erro no modal de criar subálbum: $e');
                              if (mounted) {
                                _showErrorDialog(
                                    'Você atingiu o limite de supálbuns criados: $e');
                              }
                            } finally {
                              if (context.mounted) {
                                setDialogState(() => isDialogLoading = false);
                              }
                            }
                          },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _addMultipleImages(Folder group) async {
    devtools.debugPrint(
        'Iniciando _addMultipleImages para subAlbum: ${group.nome}');

    final List<PickedFileItem> pickedFiles =
        await FilePickerHelper.pickImages(allowMultiple: true);

    if (pickedFiles.isEmpty) {
      devtools.debugPrint('Nenhuma imagem selecionada.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma imagem selecionada.')),
        );
      }
      return;
    }

    devtools.debugPrint(
        'FilePickerHelper retornou ${pickedFiles.length} PickedFileItems');

    final int? userId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || userId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro: Usuário não logado. Redirecionando...')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    try {
      final List<ImageModel> uploadedImages = await _apiService.uploadImages(
        images: pickedFiles,
        folderId: group.id,
      );
      devtools.debugPrint(
          'uploadedImages retornado: ${uploadedImages.length} itens');

      setState(() {
        final int groupIndex = _subfolders.indexOf(group);
        if (groupIndex != -1) {
          _subfolders[groupIndex].imagens ??= [];
          _subfolders[groupIndex].imagens!.addAll(uploadedImages);
          devtools.debugPrint(
              'Novas imagens adicionadas ao grupo ${group.nome}: ${_subfolders[groupIndex].imagens!.length}');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${uploadedImages.length} imagem(ns) adicionada(s) com sucesso!')),
        );
      }
    } on ApiException catch (e) {
      devtools.debugPrint('Erro em _addMultipleImages (upload): ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar imagens: ${e.message}')),
        );
        if (e.statusCode == 401) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      devtools.debugPrint('Erro inesperado em _addMultipleImages (upload): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro inesperado ao adicionar imagens: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteSubfolder(Folder subfolder) async {
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
              'Tem certeza que deseja excluir o subálbum "${subfolder.albunsCriadosPageDisplayName}"? Esta ação removerá todas as imagens e informações inseridas e não poderá ser desfeita.'),
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
        await _apiService.deleteFolder(user.id!, subfolder.id);
        await _removeTags(subfolder.id); // Remover tags persistidas

        if (mounted) {
          setState(() {
            _subfolders.removeWhere((f) => f.id == subfolder.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Subpasta "${subfolder.albunsCriadosPageDisplayName}" excluída com sucesso!')),
          );
          await _fetchSubfoldersFromApiAndRefreshState();
        }
      } on ApiException catch (e) {
        debugPrint('Erro em _confirmAndDeleteSubfolder: ${e.message}');
        if (mounted) {
          _showErrorDialog('Não foi possível excluir a subpasta: ${e.message}');
          if (e.statusCode == 401) {
            _navigateToLogin();
          }
        }
      } catch (e) {
        debugPrint('Erro inesperado em _confirmAndDeleteSubfolder: $e');
        if (mounted) {
          _showErrorDialog('Ocorreu um erro inesperado ao excluir a subpasta.');
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    return Scaffold(
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
            icon: const Icon(Icons.home, color: Colors.black, size: 24),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const PrincipalPage()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // Subalbums Section
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFaed513),
                          strokeWidth: 3,
                        ),
                      )
                    : _subfolders.isEmpty
                        ? _buildEmptyState()
                        : _buildSubalbumsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubalbumDialog,
        backgroundColor: const Color(0xFFaed513),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  // Header Section
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              // Page Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFaed513).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFaed513),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Page Title
              const Text(
                'Sub álbuns',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          Text(
            'Visualize e gerencie os sub álbuns',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
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
            'Nenhum subálbum encontrado',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.8),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro subálbum para começar\na organizar suas fotos',
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

  // Subalbums List
  Widget _buildSubalbumsList() {
    return RefreshIndicator(
      onRefresh: _fetchSubfoldersFromApiAndRefreshState,
      color: const Color(0xFFaed513),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _subfolders.length,
        itemBuilder: (context, index) {
          final group = _subfolders[index];
          final tags = group.tags ?? [];
          return _buildSubalbumCard(group, tags);
        },
      ),
    );
  }

  // Subalbum Card
  Widget _buildSubalbumCard(Folder group, List<String> tags) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImagemDetalhesPage(
                  images: group.imagens ?? [],
                  categorias: tags,
                  subAlbumName:
                      group.albunsCriadosPageDisplayName ?? 'Sem nome',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Subalbum Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFaed513).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: Color(0xFFaed513),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Subalbum Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.albunsCriadosPageDisplayName ?? 'Sem nome',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
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

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add Photos Button
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFaed513),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => _addMultipleImages(group),
                            icon: const Icon(
                              Icons.add_a_photo,
                              color: Colors.black,
                              size: 20,
                            ),
                            tooltip: 'Adicionar fotos',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete Button
                        IconButton(
                          onPressed: () => _confirmAndDeleteSubfolder(group),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.withValues(alpha: 0.8),
                            size: 20,
                          ),
                          tooltip: 'Excluir subálbum',
                        ),

                        // Arrow Icon
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),

                // Tags Section
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        tags.map((tag) => _buildTagChip(group, tag)).toList(),
                  ),
                ],

                // Add Tags Section
                const SizedBox(height: 12),
                      Row(
                        children: [
                          Row(children: [
                              IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.black.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                              onPressed: _showInsertNameTag,
                            ),
                      Text(
                      'categorias',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      onPressed: () => _showAddTagDialog(group),
                    ),
                    ],)
                    
                  ],
                ),

                // Images Preview
                if (group.imagens?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: group.imagens?.length ?? 0,
                      itemBuilder: (context, imgIndex) {
                        final img = group.imagens?[imgIndex];
                        if (img == null) return const SizedBox.shrink();
                        final String imagePath = img.url;
                        if (imagePath.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imagePath,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tag Chip
  Widget _buildTagChip(Folder group, String tag) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFaed513).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFaed513).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: const TextStyle(
                color: Color(0xFFaed513),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _removeTag(group, tag),
              child: Icon(
                Icons.close,
                color: const Color(0xFFaed513),
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

    // Função que exibe o diálogo para o usuário inserir a tag
  void _showInsertNameTag() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Criar Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _tagsController,
            decoration: InputDecoration(
              hintText: 'Ex: peso',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _tagsController.clear();
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newTag = _tagsController.text.trim();
                if (newTag.isNotEmpty) {
                  // Chama a função para adicionar a tag ao subálbum
                  _addTagToFolder(context as Folder,newTag);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Categoria "$newTag" sendo adicionada...')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Criar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

// O método para exibir o diálogo de adicionar tag
void _showAddTagDialog(Folder group) {
  // Obtenha o usuário. O método .user pode retornar null, então verificamos.
  final user = UserHelper().user;

  // Se o usuário ou o ID não existirem, mostre uma mensagem e retorne.
  if (user == null || user.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nenhum usuário logado.')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Categorias',
          style: TextStyle(color: Colors.black),
        ),
        content: FutureBuilder<List<TagModel>>(
          // A correção está aqui: passamos o id do usuário diretamente como int,
          // usando a sintaxe `user.id!` para garantir que não seja nulo,
          // pois já fizemos essa verificação acima.
          future: _apiService.getTags(user.id!),
          builder: (context, snapshot) {
            // Estado de Carregamento: mostra um indicador circular enquanto espera
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                width: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Estado de Erro ou Sem Dados: mostra uma mensagem clara para o usuário
            if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    'Nenhuma categoria disponível.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Estado de Dados Prontos: O Future foi completado e temos os dados.
            final List<TagModel> tags = snapshot.data!;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<TagModel>(
                hint: const Text('Selecione uma categoria'),
                value: null, // Valor inicial é nulo
                isExpanded: true,
                underline: const SizedBox(),
                items: tags.map((tag) {
                  return DropdownMenuItem<TagModel>(
                    value: tag,
                    child: Text(tag.nomeTag),
                  );
                }).toList(),
                onChanged: (tag) {
                  if (tag != null) {
                    _addTagToFolder(group, tag.nomeTag);
                    Navigator.of(context).pop();
                  }
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      );
    },
  );
}


}