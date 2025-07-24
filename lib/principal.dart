// lib/principal.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:application_progress/albuns_criados.dart'; // Importa a AlbunsCriadosPage
import 'package:application_progress/chat_button.dart';
import 'package:application_progress/dialog_ranking.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/main.dart' as main_app;

// IMPORTAÇÕES CORRETAS DOS MODELOS
import 'package:application_progress/models/folder_model.dart'; // Para o modelo Folder


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/infra/api_exception.dart';


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

  final ApiService _apiService = ApiService(httpClient: http.Client());

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchFoldersFromApiAndRefreshState();
  }

  Future<void> _fetchFolders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserHelper().user;
      if (user != null && user.pastas != null) {
        final List<Folder> newFolders = user.pastas!;
        if (mounted) {
          setState(() {
            _folders = newFolders;
            debugPrint('Pastas carregadas do UserHelper: ${_folders.length}');
          });
        }
      } else {
        debugPrint('Pastas não encontradas no UserHelper. Redirecionando para login.');
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('Erro inesperado em _fetchFolders (do UserHelper): $e');
      if (mounted) {
        _showErrorDialog('Ocorreu um erro inesperado ao carregar seus álbuns.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addFolder(String folderName) async {
    final user = UserHelper().user;
    if (user == null || user.id == null || user.nome == null) {
      debugPrint('Tentativa de criar pasta sem usuário ou ID válido. Usuário: $user');
      _showErrorDialog('Erro: Usuário não logado ou ID de usuário inválido. Por favor, faça login novamente.');
      _navigateToLogin();
      return;
    }

    try {
      // ⭐ CORREÇÃO AQUI: Construindo o nome completo da pasta para a API
      // Assume que o nome do usuário já está formatado como "PrimeiroNome Sobrenome"
      // e o backend espera "PrimeiroNome_Sobrenome/NomeDaPasta"
      final String userNameFormatted = user.nome!.replaceAll(' ', '_'); // Substitui espaços por underscores
      final String fullFolderNameForApi = "$userNameFormatted/$folderName";
      debugPrint('Tentando criar pasta com nome: $fullFolderNameForApi');


      await _apiService.createSubFolder(
        folderName: fullFolderNameForApi, // Nome completo da pasta para a API
        tags: [], // Sem tags iniciais, se não for necessário
        parentFolderId: null, // É uma pasta principal
      );

      if (mounted) {
        folderNameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Álbum "$folderName" criado com sucesso!')),
        );
        await _fetchFoldersFromApiAndRefreshState();
      }
    } on ApiException catch (e) {
      debugPrint('Erro ao criar álbum: ${e.message}');
      if (mounted) {
        _showErrorDialog('Falha ao criar o álbum: ${e.message}');
        if (e.statusCode == 401) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      debugPrint('Erro inesperado ao criar álbum: $e');
      if (mounted) {
        _showErrorDialog('Ocorreu um erro inesperado ao criar o álbum.');
      }
    }
  }

  Future<void> _fetchFoldersFromApiAndRefreshState() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    debugPrint('PrincipalPage: Token no início de _fetchFoldersFromApiAndRefreshState: ${TokenHelper().token}');

    try {
      final user = UserHelper().user;
      if (user == null || user.id == null) {
        debugPrint('Usuário não autenticado em _fetchFoldersFromApiAndRefreshState. Redirecionando para login.');
        _navigateToLogin();
        return;
      }

      final List<Folder> fetchedFolders = user.pastas ?? [];

      if (mounted) {
        setState(() {
          _folders = fetchedFolders;
          debugPrint('Pastas atualizadas do UserHelper: ${_folders.length}');
        });
      }
    } on ApiException catch (e) {
      debugPrint('Erro ao atualizar pastas da API: ${e.message}');
      if (mounted) {
        _showErrorDialog('Não foi possível atualizar seus álbuns. ${e.message}');
        if (e.statusCode == 401) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      debugPrint('Erro inesperado ao atualizar pastas da API: $e');
      if (mounted) {
        _showErrorDialog('Ocorreu um erro inesperado ao atualizar seus álbuns.');
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
          content: Text('Tem certeza que deseja excluir a pasta "${folder.principalPageDisplayName}"? Esta ação removerá todas as imagens dentro dela e não poderá ser desfeita.'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pasta "${folder.principalPageDisplayName}" excluída com sucesso!')),
          );
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
                    decoration: const InputDecoration(hintText: "Nome do Álbum"),
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
                    folderNameController.clear();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading ? null : () async {
                    String folderName = folderNameController.text.trim();
                    if (folderName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, insira um nome para o álbum.')),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatButton(),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFaed513),
        title: const Text('Meus Álbuns', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchFoldersFromApiAndRefreshState,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFaed513)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _showAModal,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: const Color(0xFFaed513),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        ),
                        child: const Icon(Icons.add_sharp, size: 25),
                      ),
                      GestureDetector(
                        onTap: _showAModal,
                        child: const Text(
                          '''   Aperte   aqui
      para   criar
    um novo álbum''',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                          'Álbuns Criados',
                          style: TextStyle(color: Colors.white, fontSize: 30),
                      ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Buscar pastas...',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: _folders.isEmpty && !_isLoading
                        ? const Center(
                            child: Text(
                              'Nenhum álbum encontrado.\nCrie um novo álbum para começar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchFoldersFromApiAndRefreshState,
                            child: ListView.builder(
                              itemCount: _folders.length,
                              itemBuilder: (context, index) {
                                final folder = _folders[index];
                                if (_searchQuery.isNotEmpty &&
                                        !folder.principalPageDisplayName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                                  return const SizedBox.shrink();
                                }
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbunsCriadosPage(
                                          initialFolderName: folder.principalPageDisplayName,
                                          initialFolderId: folder.id,
                                          folderApiPath: folder.caminho, // Passa o caminho completo da pasta
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                      color: Colors.grey[900],
                                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: ListTile(
                                      leading: const Icon(Icons.folder, color: Colors.white, size: 40),
                                      title: Text(
                                        folder.principalPageDisplayName,
                                        style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                                      ),
                                      trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmAndDeleteFolder(folder),
                                      ),
                                      ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFaed513),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Menu', style: TextStyle(color: Colors.black, fontSize: 24)),
                  const SizedBox(height: 40,),
                  Text(UserHelper().user?.nome ?? 'Convidado',
                      style: const TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Ranking'),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (context) => DialogRanking());
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sair'),
              onTap: () async {
                await TokenHelper().clearToken();
                await UserHelper().removeUser();
                _navigateToLogin();
              },
            ),
          ],
        ),
      ),
    );
  }
}
