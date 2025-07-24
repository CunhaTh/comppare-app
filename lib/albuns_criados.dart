// lib/albuns_criados.dart

import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/infra/api_services.dart'; // Usar ApiService
import 'package:application_progress/models/image_model.dart';
import 'package:application_progress/views/comppareimg.dart' hide FilePickerHelper; // ImagemDetalhesPage
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Importa FilePicker
import 'package:flutter/foundation.dart';
import 'dart:developer' as devtools;

// Meus imports
import 'package:application_progress/models/image_model.dart'; // Contém MyImage, ImageGroup e PickedFileItem
import 'package:application_progress/main.dart' as main_app;
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/login.dart';

// Importa o FilePickerHelper que acabamos de ajustar
import 'package:application_progress/file_picker_helper.dart';
import 'package:flutter/material.dart' as devtools;


class AlbunsCriadosPage extends StatefulWidget {
  final String initialFolderName; // Nome da pasta principal (do PrincipalPage)
  final int initialFolderId; // ID da pasta selecionada
  final String folderApiPath; // Caminho da API para a pasta pai (ex: "Thiago Gomes_Cunha/FirstFolder/firsSubfolder")

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
  List<ImageGroup> imageGroups = []; // Esta lista será a fonte única de dados
  bool _isLoading = true;
  final ApiService _apiService = ApiService(); // Usar ApiService

  final TextEditingController _subalbumNameController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSubfolders();
  }

  @override
  void dispose() {
    _subalbumNameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubfolders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final int? userId = TokenHelper().userId; // Obtenha userId do TokenHelper

    if (!TokenHelper().hasToken() || userId == null || userId == 0) {
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
      // ⭐ AJUSTE AQUI: Chamar o novo método do ApiService
      final List<ImageGroup> fetchedGroups = await _apiService.fetchSubfoldersAndImages(
        widget.initialFolderId, // Passa o ID da pasta pai
      );

      if (mounted) {
        setState(() {
          imageGroups = fetchedGroups;
        });
        devtools.debugPrint('Subálbuns carregados: ${imageGroups.map((g) => g.folderName).join(', ')}');
      }
    } on ApiException catch (e) {
      devtools.debugPrint('Erro na API ao carregar subálbuns: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar subálbuns: ${e.message}')),
        );
        if (e.statusCode == 401) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      devtools.debugPrint('Erro inesperado ao carregar subálbuns: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado ao carregar subálbuns: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _showAddSubalbumDialog() {
    _subalbumNameController.clear();
    _tagsController.clear();

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 520 && MediaQuery.of(context).size.height > 889;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                if (_subalbumNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome do subálbum não pode ser vazio.')),
                  );
                  return;
                }

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

                Navigator.of(context).pop(); // Fecha o dialog antes de iniciar a criação

                try {
                  final String newSubalbumName = _subalbumNameController.text.trim();

                  // Construindo o nome completo da pasta para a API
                  // A API espera "PastaPai/NomeDaSubpasta"
                  // widget.folderApiPath já deve vir como "Usuario/NomeDaPastaPai"
                  final String parentPathWithoutUser = widget.folderApiPath.split('/').skip(1).join('/');
                  final String fullFolderNameForApi = "$parentPathWithoutUser/$newSubalbumName";
                  devtools.log('Tentando criar subálbum com nome: $fullFolderNameForApi');


                  final int newFolderId = await _apiService.createSubFolder( // Usar ApiService
                    folderName: fullFolderNameForApi,
                    tags: _tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList(),
                    parentFolderId: widget.initialFolderId, // Passa o ID da pasta pai
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Subálbum criado com sucesso!')),
                    );

                    await _fetchSubfolders(); // Atualiza a lista para incluir o novo subálbum

                    // Lógica para adicionar imagens imediatamente ao novo grupo
                    ImageGroup? newGroup;
                    for (var group in imageGroups) {
                      if (group.folderId == newFolderId) {
                        newGroup = group;
                        break;
                      }
                    }

                    if (newGroup != null) {
                      _addMultipleImages(newGroup); // Permite adicionar imagens ao novo subálbum
                    } else {
                      devtools.debugPrint('Erro: Subálbum recém-criado não encontrado na lista após fetch.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subálbum criado, mas não foi possível carregar imagens automaticamente. Tente adicionar imagens manualmente.')),
                      );
                    }
                  }
                } on ApiException catch (e) {
                  devtools.debugPrint('Erro ao criar subálbum: ${e.message}');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao criar subálbum: ${e.message}')),
                    );
                    if (e.statusCode == 401) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
                  }
                } catch (e) {
                  devtools.debugPrint('Erro inesperado ao criar subálbum: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro inesperado ao criar subálbum: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  void _addMultipleImages(ImageGroup group) async {
    devtools.debugPrint('Iniciando _addMultipleImages para subAlbum: ${group.folderName}');

    // ⭐ AJUSTE AQUI: Chamar o FilePickerHelper para obter PickedFileItem
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
      // ⭐ AJUSTE AQUI: Enviar PickedFileItem para o ApiService
      final List<MyImage> uploadedImages = await _apiService.uploadImages(
        images: pickedFiles,
        folderId: group.folderId,
      );

      setState(() {
        final int groupIndex = imageGroups.indexOf(group);
        if (groupIndex != -1) {
          // Adiciona as MyImage retornadas pela API ao ImageGroup
          imageGroups[groupIndex].images.addAll(uploadedImages);
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

  Future<void> _deleteFolder(ImageGroup groupToDelete) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o subálbum "${groupToDelete.albunsCriadosDisplayName}" e todas as suas imagens?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
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
        final userId = TokenHelper().userId; // Usar TokenHelper
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

        await _apiService.deleteFolder(userId, groupToDelete.folderId); // Usar ApiService e userId

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subálbum "${groupToDelete.albunsCriadosDisplayName}" excluído com sucesso!')),
          );
          await _fetchSubfolders(); // Recarregar a lista de pastas após a exclusão
        }
      } on ApiException catch (e) {
        devtools.debugPrint('Erro ao excluir subálbum: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir subálbum: ${e.message}')),
          );
          if (e.statusCode == 401) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } catch (e) {
        devtools.debugPrint('Erro inesperado ao excluir subálbum: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro inesperado ao excluir subálbum: ${e.toString()}')),
          );
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
              MaterialPageRoute(builder: (context) => const main_app.MyHomePage(title: '')),
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
              child: Icon(Icons.arrow_back, size: isLargeScreen ? screenWidth * 0.05 : screenWidth * 0.067),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSubfolders,
        color: const Color(0xffFaed513),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFaed513)))
            : imageGroups.isEmpty
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
                    itemCount: imageGroups.length,
                    itemBuilder: (context, index) {
                      final group = imageGroups[index];
                      return GestureDetector(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImagemDetalhesPage(
                                images: group.images,
                                tags: group.tags,
                                subAlbumName: group.albunsCriadosDisplayName,
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
                                        group.albunsCriadosDisplayName, // Nome da subpasta
                                        style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteFolder(group),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: group.tags.map((tag) => Chip(
                                        label: Text(tag, style: const TextStyle(color: Colors.black)),
                                        backgroundColor: Colors.amberAccent,
                                      )).toList(),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _addMultipleImages(group),
                                    icon: const Icon(Icons.add_photo_alternate, color: Colors.black),
                                    label: const Text('Adicionar Imagens', style: TextStyle(color: Colors.black)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFaed513),
                                    ),
                                  ),
                                ),
                                if (group.images.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: group.images.length,
                                      itemBuilder: (context, imgIndex) {
                                        final img = group.images[imgIndex];
                                        if (img.path.isNotEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Image.network(
                                              img.path,
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
