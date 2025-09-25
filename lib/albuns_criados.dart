import 'dart:convert';
import 'dart:js_interop';

import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/repositories/ranking_repository.dart';
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

  Map<String, int> _availableTagsMap = {};

  final ApiService _apiService = ApiService(httpClient: http.Client());
  

  @override
  void initState() {
    super.initState();
   // _loadAvailableTags();
   // _fetchSubfoldersFromApiAndRefreshState();
    _initializeData();
  }

  @override
  void dispose() {
    _subalbumNameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

Future<void> _initializeData() async {
  // Primeiro, ESPERA o mapa de tags ser carregado e preparado
  await _loadAllAvailableTags();
  
  // SÓ DEPOIS, busca e exibe os subálbuns
  await _fetchSubfoldersFromApiAndRefreshState();
}

// 3. Função que busca todas as tags e prepara o mapa
Future<void> _loadAllAvailableTags() async {
  final user = UserHelper().user;
  if (user == null || user.id == null) return;
  try {
    // Apenas chame a função. O ApiService cuida de API e cache.
    final tagsFromApi = await _apiService.getTags(user.id!);
    if (mounted) {
      setState(() {
        _availableTagsMap = {for (var tag in tagsFromApi) tag.nomeTag: tag.id};
      });
    }
  } catch (e) {
    debugPrint('Erro ao carregar tags disponíveis: $e');
  }
}


// 5. Função que REMOVE a tag e CHAMA a função de persistência
void _removeTag(Folder group, String tagName) {
  setState(() {
    group.tags?.remove(tagName);
  });
  _persistUpdatedTagsForGroup(group);
}

// 6. A função MESTRA que monta os dados e efetivamente chama a API
Future<void> _persistUpdatedTagsForGroup(Folder group) async {
  final user = UserHelper().user;
  if (user == null || user.id == null) return;

  debugPrint('----------------- INICIANDO DEPURAÇÃO -----------------');
  debugPrint('DEBUG: Tags atualmente no objeto group: ${group.tags}');
  debugPrint('DEBUG: Conteúdo do mapa de consulta _availableTagsMap: $_availableTagsMap');

  final List<int> tagIds = (group.tags ?? [])
      .map((tagName) => _availableTagsMap[tagName])
      .where((id) => id != null)
      .cast<int>()
      .toList();
  
  debugPrint('>>> Enviando para API a atualização da pasta ${group.id}. IDs das tags: $tagIds');

  try {
    await _apiService.updateFolder(
      folderId: group.id,
      idUsuario: user.id!,
      folderName: group.nome,
      tagIds: tagIds,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categorias salvas na nuvem!'), duration: Duration(seconds: 2)),
      );
    }
  } catch (e) {
    _showErrorDialog('Não foi possível salvar as categorias.');
    _fetchSubfoldersFromApiAndRefreshState(); 
  }
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


// 4. Função que ADICIONA a tag e CHAMA a função de persistência
void _addTagToFolder(Folder group, TagModel tag) {
  setState(() {
    final currentTags = group.tags ?? [];
    if (!currentTags.contains(tag.nomeTag)) {
      group.tags = [...currentTags, tag.nomeTag];
    }
  });
  _persistUpdatedTagsForGroup(group);
}


  // FUNÇÃO DE ATUALIZAÇÃO PRINCIPAL - Busca a lista mais recente da API
  Future<void> _fetchSubfoldersFromApiAndRefreshState() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<Folder> subfolders =
          await _apiService.fetchSubfolders(widget.initialFolderId);

      if (mounted) {
        setState(() {
          _subfolders = subfolders;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao carregar subálbuns: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// **CORRIGIDO:** Cria um subálbum na API e atualiza o estado local com a resposta.
  Future<void> _addSubfolderAndUpdateState(String subfolderName) async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      _showErrorDialog('Erro: Usuário não logado.');
      _navigateToLogin();
      return;
    }

  try {
    // A MUDANÇA ESTÁ AQUI:
    final Map<String, dynamic> response = await _apiService.createSubFolder(
      parentFolderId: widget.initialFolderId,
      idUsuario: user.id!,
      folderName: subfolderName,
      // Antes: parentFolderPath: widget.folderApiPath,
      parentFolderName: widget.initialFolderName, // DEPOIS: Passando o nome da pasta pai
    );

      // Cria o objeto Folder com os dados retornados pela API
      final newSubfolder = Folder.fromMap({
        'id': response['pasta_id'] ?? 0,
        'nome': response['pasta_nome'] ?? subfolderName,
        'caminho': response['pasta_caminho'] ?? '',
        'idPastaPai': widget.initialFolderId,
        'imagens': [],
        'subpastas': [],
      });

      // Adiciona o novo subálbum à lista local e atualiza a tela
      if (mounted) {
        setState(() {
          _subfolders.add(newSubfolder);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subálbum "$subfolderName" criado com sucesso!')),
        );
      }
      
      await RankingRepository.instance.addSubAlbumPoints();
       
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Falha ao criar o subálbum: Você atingiu o limite de subálbuns criados.');
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                                  'Criar Novo Subálbum',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Dê um nome para seu Subálbum',
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
                          controller: _subalbumNameController,
                          enabled: !isDialogLoading,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: Meu SubAlbum',
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
                            isDialogLoading ? null : () => Navigator.of(dialogContext).pop();
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
                              onPressed: isDialogLoading ? null : () => Navigator.of(dialogContext).pop(),
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
                                            final subalbumName = _subalbumNameController.text.trim();
                                            if (subalbumName.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('O nome não pode ser vazio.')),
                                              );
                                              return;
                                            }
                                            
                                            setDialogState(() => isDialogLoading = true);
                                            // Chama a nova função unificada
                                            await _addSubfolderAndUpdateState(subalbumName);
                                            if (mounted) {
                                              Navigator.of(dialogContext).pop();
                                            }
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
                                isDialogLoading ? 'Criando...' : 'Criar Subálbum',
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

     /* setState(() {
        final int groupIndex = _subfolders.indexOf(group);
        if (groupIndex != -1) {
          _subfolders[groupIndex].imagens ??= [];
          _subfolders[groupIndex].imagens!.addAll(uploadedImages);
          devtools.debugPrint(
              'Novas imagens adicionadas ao grupo ${group.nome}: ${_subfolders[groupIndex].imagens!.length}');
               
               Future.delayed(const Duration(seconds: 2));
               
               RankingRepository.instance.recalculateAndUpdateScore();  
        }
        
      });*/

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${uploadedImages.length} imagem(ns) adicionada(s) com sucesso!')),
        );
      }
       // 3. Após o sucesso, busca TODOS os dados do servidor novamente.
      // Isso garante que os IDs das novas imagens estarão corretos no estado do seu app.
      await _fetchSubfoldersFromApiAndRefreshState();

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

  /// **CORRIGIDO:** Exclui um subálbum na API e atualiza o estado local após o sucesso.
  Future<void> _confirmAndDeleteSubfolder(Folder subfolder) async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      _navigateToLogin();
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o subálbum "${subfolder.albunsCriadosPageDisplayName}"?'),
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
      setState(() => _isLoading = true);
      try {
        await _apiService.deleteFolder(user.id!, subfolder.id);
        
        await RankingRepository.instance.removeSubAlbumPoints();
        
        if (mounted) {
          setState(() {
            _subfolders.removeWhere((f) => f.id == subfolder.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subálbum "${subfolder.albunsCriadosPageDisplayName}" excluído com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Não foi possível excluir o subálbum: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
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
            tooltip: 'HomesPage',
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
   /*   floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubalbumDialog,
        backgroundColor: const Color(0xFFaed513),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),*/
    );
  }
  

    Widget _buildHeaderSection() {
    return GestureDetector(
      onTap: _showAddSubalbumDialog,
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
                  onTap: _showAddSubalbumDialog,
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
                    'Criar Subálbuns',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visualize e gerencie os subálbuns',
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


  // Header Section
 /* Widget _buildHeaderSection() {
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
                'Subálbuns',
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
  }*/

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

// 1. Widget que constrói a lista de subálbuns
Widget _buildSubalbumsList() {
  return RefreshIndicator(
    onRefresh: _fetchSubfoldersFromApiAndRefreshState,
    color: const Color(0xFFaed513),
    child: ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _subfolders.length,
      itemBuilder: (context, index) {
        final group = _subfolders[index];
        // AJUSTE AQUI: Passamos apenas o objeto 'group' completo.
        return _buildSubalbumCard(group);
      },
    ),
  );
}

  // Subalbum Card
  Widget _buildSubalbumCard(Folder group) {
    final List<String> tags = group.tags ?? [];
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
                // AJUSTE AQUI: Passa a lista de tags correta para a próxima tela
                categorias: tags, 
                subAlbumName: group.albunsCriadosPageDisplayName ?? 'Sem nome',
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
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                  ),
                                child: Icon(
                                        Icons.add,
                                        // ignore: deprecated_member_use
                                        color: Colors.black.withOpacity(0.7),
                                        size: 20,
                                        ),
                                        ),
                                onPressed: () {
                                  // Aqui a gente cria uma função anônima que não retorna nada
                                  // e passa ela para o showInsertNameTag.
                                  // Desta forma, a chamada `loadTags()` não é executada imediatamente,
                                  // mas sim passada como um callback.
                                  _showInsertNameTag(context, _apiService, () => _loadTags);
                                },
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

  
// Não se esqueça de ter esta função auxiliar também
Widget _buildTagChip(Folder group, String tagName) {
  return Chip(
    label: Text(tagName, style: const TextStyle(color: Colors.black)),
    backgroundColor: const Color(0xFFaed513).withOpacity(0.2),
    deleteIcon: const Icon(Icons.close, size: 16),
    onDeleted: () {
      _removeTag(group, tagName);
    },
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}

// A função que se comunica com a API para criar a tag, baseada no seu exemplo
Future<void> _createTagsOnApi(String nomeTag, ApiService _apiService, VoidCallback _loadTags) async {
  final user = UserHelper().user;
  if (user == null || user.id == null) {
    debugPrint('Erro: usuário não logado.');
    return;
  }
  try {
    // Use o seu método saveTags real aqui
    await _apiService.saveTags(
      nomeTag: nomeTag,
      usuario: user.id!,
    );
    debugPrint('Tags sincronizadas com a API: Sucesso!');
    // Recarrega as tags para atualizar o DropdownButton
    _loadTags();
  } catch (e) {
    debugPrint('Erro ao sincronizar tags com a API: $e');
  }
}  

// O método que abre o diálogo de criação de tag
Future<void> _showInsertNameTag(BuildContext context, ApiService _apiService, VoidCallback _loadTags) async {
  final _tagController = TextEditingController();

  // Get the user. The .user method can return null, so we check.
  final user = UserHelper().user;

  // If the user or the ID don't exist, show a message and return.
  if (user == null || user.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nenhum usuário logado.')),
    );
    return;
  }

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        title: const Text(
          'Criar Nova Categoria',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _tagController,
          decoration: InputDecoration(
            labelText: 'Nome da Categoria',
            hintText: 'Ex: Treino',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
          ),
          style: const TextStyle(color: Colors.black),
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
            onPressed: () async {
              final String newTag = _tagController.text.trim();
              if (newTag.isNotEmpty) {
                // Chama a função para criar a tag na API
                await _createTagsOnApi(newTag, _apiService, _loadTags);
                Navigator.of(context).pop(); // Fecha o diálogo após a tentativa de criação
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O nome da categoria não pode ser vazio.')),
                );
              }
            }, style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
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
                   // _addTagToFolder(group, tag.nomeTag);
                   _addTagToFolder(group, tag);
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