import 'dart:convert';

import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/models/image_model.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/comppareimg.dart' hide FilePickerHelper;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as devtools;

// Meus imports
import 'package:application_progress/models/image_model.dart';
import 'package:application_progress/main.dart' as main_app;
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/file_picker_helper.dart';
import 'package:flutter/material.dart' as devtools;
import 'package:http/http.dart' as http;

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

  String _searchQuery = '';
  List<Folder> _subfolders = [];
  bool _isLoading = true;

  final ApiService _apiService = ApiService(httpClient: http.Client());

  // Método para salvar tags no shared_preferences
  Future<void> _saveTags(int folderId, List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tags_$folderId', jsonEncode(tags));
    debugPrint('Tags salvas localmente para folderId $folderId: ${tags.join(",")}');
  }

  // Método para recuperar tags do shared_preferences
  Future<List<String>> _loadTags(int folderId) async {
    final prefs = await SharedPreferences.getInstance();
    final tagsString = prefs.getString('tags_$folderId');
    return tagsString != null ? (jsonDecode(tagsString) as List<dynamic>).map((t) => t.toString()).toList() : [];
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

  @override
  void initState() {
    super.initState();
    _fetchSubfoldersFromApiAndRefreshState();
  }

  @override
  void dispose() {
    _subalbumNameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  

  Future<void> _fetchSubfoldersFromApiAndRefreshState() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    debugPrint('AlbunsCriados: Token no início de _fetchSubfoldersFromApiAndRefreshState: ${TokenHelper().token}');
    debugPrint('AlbunsCriados: Buscando subpastas para initialFolderId: ${widget.initialFolderId}');

    try {
      final user = UserHelper().user;
      if (user == null || user.id == null || !TokenHelper().hasToken()) {
        debugPrint('Usuário não autenticado ou token ausente. Redirecionando para login.');
        _navigateToLogin();
        return;
      }

      final List<Folder> subfolders = await _apiService.fetchSubfolders(widget.initialFolderId);
      debugPrint('Subpastas recebidas da API: ${subfolders.map((f) => 'id=${f.id}, nome=${f.nome}, idPastaPai=${f.idPastaPai}, tags=${f.tags?.join(",") ?? "nenhuma"}').join(', ')}');

      if (mounted) {
        final updatedSubfolders = await Future.wait(subfolders.map((f) async {
          final localTags = await _loadTags(f.id);
          return copyFolder(f, tags: localTags.isNotEmpty ? localTags : f.tags ?? []);
        }).toList());
        setState(() {
          _subfolders = updatedSubfolders;
          debugPrint('Subpastas atualizadas: ${_subfolders.length}');
        });
      }
    } on ApiException catch (e) {
      debugPrint('Erro ao atualizar subpastas da API: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar subpastas: ${e.message}')),
        );
        if (e.statusCode == 401) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      debugPrint('Erro inesperado ao atualizar subpastas da API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorreu um erro inesperado ao carregar subpastas.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSubfolder(String subfolderName, List<String> tags) async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      debugPrint('[_addSubfolder] Tentativa de criar subpasta sem usuário ou ID válido.');
      _showErrorDialog('Erro: Usuário não logado. Faça login novamente.');
      _navigateToLogin();
      return;
    }

    try {
      final String subfolderNameForApi = subfolderName.trim();
      debugPrint('[_addSubfolder] Tentando criar subpasta com nome: $subfolderNameForApi, parentFolderId: ${widget.initialFolderId}, parentFolderPath: ${widget.folderApiPath}, tags: ${tags.join(",")}');

      final response = await _apiService.createSubFolder(
        parentFolderId: widget.initialFolderId,
        idUsuario: user.id!,
        folderName: subfolderNameForApi,
        parentFolderPath: widget.folderApiPath,
        tags: tags,
      );
      debugPrint('[_addSubfolder] Subpasta criada com sucesso, resposta: ${json.encode(response)}');

      if (response is Map<String, dynamic> && mounted) {
        final newSubfolder = Folder.fromMap({
          'id': response['pasta_id'] ?? 0,
          'nome': response['estrutura_completa'] ?? '${response['pasta_nome'] ?? subfolderNameForApi}',
          'caminho': response['pasta_caminho'],
          'idPastaPai': widget.initialFolderId,
          'imagens': [],
          'subpastas': [],
          'tags': (response['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? tags,
        });
        await _saveTags(newSubfolder.id, tags); // Salvar tags localmente
        setState(() {
          _subfolders.add(newSubfolder);
        });
        debugPrint('[_addSubfolder] Subpasta adicionada localmente: id=${newSubfolder.id}, nome=${newSubfolder.nome}, idPastaPai=${newSubfolder.idPastaPai}, tags=${newSubfolder.tags?.join(",") ?? "nenhuma"}');
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
          SnackBar(content: Text('Subpasta "$subfolderName" criada com sucesso!')),
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
    TokenHelper().clearToken();
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
    final isLargeScreen = screenWidth > 520 && MediaQuery.of(context).size.height > 889;

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
                          horizontal: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028,
                          vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022,
                        ),
                      ),
                      enabled: !isDialogLoading,
                    ),
                    TextField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        hintText: 'Tags (separadas por vírgula)',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028,
                          vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022,
                        ),
                      ),
                      enabled: !isDialogLoading,
                    ),
                    if (isDialogLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isDialogLoading ? null : () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isDialogLoading ? null : () async {
                      final subalbumName = _subalbumNameController.text.trim();
                      if (subalbumName.isEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('O nome do subálbum não pode ser vazio.')),
                          );
                        }
                        return;
                      }

                      final tagsString = _tagsController.text.trim();
                      final List<String> tags = tagsString.isNotEmpty
                          ? tagsString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList()
                          : [];

                      setDialogState(() => isDialogLoading = true);
                      try {
                        await _addSubfolder(subalbumName, tags);
                        if (context.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      } catch (e) {
                        debugPrint('Erro no modal de criar subálbum: $e');
                        if (mounted) {
                          _showErrorDialog('Falha ao criar subpasta: $e');
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isDialogLoading = false);
                        }
                      }
                    },
                    child: const Text('Salvar'),
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
    devtools.debugPrint('Iniciando _addMultipleImages para subAlbum: ${group.nome}');

    final List<PickedFileItem> pickedFiles = await FilePickerHelper.pickImages(allowMultiple: true);

    if (pickedFiles.isEmpty) {
      devtools.debugPrint('Nenhuma imagem selecionada.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma imagem selecionada.')),
        );
      }
      return;
    }

    devtools.debugPrint('FilePickerHelper retornou ${pickedFiles.length} PickedFileItems');

    final int userId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || userId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não logado. Redirecionando...')),
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
      devtools.debugPrint('uploadedImages retornado: ${uploadedImages.length} itens');

      setState(() {
        final int groupIndex = _subfolders.indexOf(group);
        if (groupIndex != -1) {
          _subfolders[groupIndex].imagens ??= [];
          _subfolders[groupIndex].imagens!.addAll(uploadedImages);
          devtools.debugPrint('Novas imagens adicionadas ao grupo ${group.nome}: ${_subfolders[groupIndex].imagens!.length}');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${uploadedImages.length} imagem(ns) adicionada(s) com sucesso!')),
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
          SnackBar(content: Text('Erro inesperado ao adicionar imagens: ${e.toString()}')),
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
          content: Text('Tem certeza que deseja excluir a subpasta "${subfolder.albunsCriadosPageDisplayName}"? Esta ação removerá todas as imagens dentro dela e não poderá ser desfeita.'),
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
            SnackBar(content: Text('Subpasta "${subfolder.albunsCriadosPageDisplayName}" excluída com sucesso!')),
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
      appBar: AppBar(
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
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.05),
            child: GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const main_app.MyHomePage(title: '')),
                  (Route<dynamic> route) => false,
                );
              },
              child: Icon(Icons.exit_to_app, size: isLargeScreen ? screenWidth * 0.05 : screenWidth * 0.067),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSubfoldersFromApiAndRefreshState,
        color: const Color(0xFFaed513),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFaed513)))
            : _subfolders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nenhum subálbum encontrado. Crie um novo!',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _subfolders.length,
                    itemBuilder: (context, index) {
                      final group = _subfolders[index];
                      final tags = group.tags ?? [];
                      debugPrint('ListView: index=$index, nome=${group.nome}, idPastaPai=${group.idPastaPai}, albunsCriadosPageDisplayName=${group.albunsCriadosPageDisplayName}, tags=${tags.join(",") ?? "nenhuma"}');
                      return GestureDetector(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImagemDetalhesPage(
                                images: group.imagens ?? [],
                                tags: tags,
                                subAlbumName: group.albunsCriadosPageDisplayName ?? 'Sem nome',
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.folder, color: Colors.white, size: 40),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        group.albunsCriadosPageDisplayName ?? 'Sem nome',
                                        style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmAndDeleteSubfolder(group),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Wrap(
                                      spacing: 8.0,
                                      children: tags.map((tag) => Chip(
                                            label: Text(tag, style: const TextStyle(color: Colors.black)),
                                            backgroundColor: Colors.amberAccent,
                                            deleteIcon: const Icon(Icons.close, size: 18),
                                            onDeleted: () => _removeTag(group, tag),
                                          )).toList(),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _addMultipleImages(group),
                                      icon: const Icon(Icons.add_a_photo, color: Colors.black),
                                      label: const Text('Imagens', style: TextStyle(color: Colors.black)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFaed513),
                                      ),
                                    ),
                                  ],
                                ),
                                if (group.imagens?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 8),
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
                                          return Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Image.network(
                                              imagePath,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: Colors.grey,
                                                  child: const Center(child: Icon(Icons.broken_image, color: Colors.red)),
                                                );
                                              },
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
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubalbumDialog,
        backgroundColor: const Color(0xFFaed513),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}