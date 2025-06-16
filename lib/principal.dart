import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:application_progress/albuns_criados.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/dialog_ranking.dart';
import 'package:application_progress/chat_button.dart';
import 'dart:convert';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comparação de Projetos',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final user = UserHelper.instance.user;
    if (user == null) {
      return const LoginScreen();
    } else {
      return const PrincipalPage();
    }
  }
}

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class ImageItem {
  final Uint8List imageData;
  final String subAlbumName;

  ImageItem({required this.imageData, required this.subAlbumName});

  // Método para converter ImageItem em JSON
  Map<String, dynamic> toJson() {
    return {
      'imageData': imageData.toList(), // Converte Uint8List para List<int>
      'subAlbumName': subAlbumName,
    };
  }

  // Método para criar ImageItem a partir de JSON
  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      imageData: Uint8List.fromList(List<int>.from(json['imageData'])),
      subAlbumName: json['subAlbumName'] as String,
    );
  }
}

class ImageGroup {
  final String subAlbumName;
  final List<ImageItem> images;
  List<String> tags;
  final DateTime? creationDate;

  ImageGroup({
    required this.subAlbumName,
    required this.images,
    this.tags = const [],
    this.creationDate,
  });

  // Método para converter ImageGroup em JSON
  Map<String, dynamic> toJson() {
    return {
      'subAlbumName': subAlbumName,
      'images': images.map((item) => item.toJson()).toList(),
      'tags': tags,
      'creationDate': creationDate?.toIso8601String(),
    };
  }

  // Método para criar ImageGroup a partir de JSON
  factory ImageGroup.fromJson(Map<String, dynamic> json) {
    return ImageGroup(
      subAlbumName: json['subAlbumName'] as String,
      images: (json['images'] as List<dynamic>)
          .map((item) => ImageItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      tags: List<String>.from(json['tags'] ?? []),
      creationDate: json['creationDate'] != null
          ? DateTime.parse(json['creationDate'] as String)
          : null,
    );
  }
}

class Folder {
  final int? id;
  final String name;
  final DateTime? creationDate;
  final List<ImageGroup> subfolders;

  Folder({
    this.id,
    required this.name,
    this.creationDate,
    List<ImageGroup>? subfolders,
  }) : subfolders = subfolders ?? [];
}

class _PrincipalPageState extends State<PrincipalPage> {
  final List<Folder> _folders = [];
  String _searchQuery = '';
  final TextEditingController folderNameController = TextEditingController();
  bool _isLoading = false;
  int _localIdCounter = 1;

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    setState(() {
      _isLoading = true;
    });
    setState(() {
      _isLoading = false;
    });
  }
  void _addFolder(String folderName, DateTime? dateTime) {
      setState(() {
        if (folderName.isNotEmpty) {
          final newFolder = Folder(
            id: _localIdCounter++,
            name: folderName,
            creationDate: dateTime ?? DateTime.now(),
            subfolders: [], // Inicializa com subfolders vazios
          );
          _folders.add(newFolder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pasta criada com sucesso!')),
          );
        }
      });
    }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFolder(String folderName) async {
    // Deletion handled locally
  }

  Future<Folder?> _createFolder(String folderName) async {
    return Folder(
      id: _localIdCounter++,
      name: folderName,
      creationDate: DateTime.now(),
    );
  }

  Future<void> _showAModal() async {
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Álbum'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: folderNameController,
                  decoration: const InputDecoration(hintText: "Nome do Álbum"),
                ),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    selectedDate != null
                        ? 'Data Selecionada: ${selectedDate!.toLocal()}'
                            .split(' ')[0]
                        : 'Selecionar Data (Opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  _addFolder(folderName, selectedDate);
                  folderNameController.clear();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, insira um nome para a pasta.')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _categoryModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SubÁlbum Criado'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                "assets/logo_cortada.png",
                width: 150.w,
                height: 50.h,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150.w,
                    height: 50.h,
                    color: Colors.grey,
                    child: const Center(child: Text('Logo não carregado')),
                  );
                },
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          '''   Aperte  aqui 
     para  criar 
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
                    padding: const EdgeInsets.only(bottom: 50),
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
  child: Stack(
    children: [
      ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          if (_searchQuery.isNotEmpty &&
              !folder.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return const SizedBox.shrink();
          }
          return Dismissible(
            key: Key(folder.name),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16.0),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) async {
              final removedFolder = _folders[index];
              setState(() {
                _folders.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pasta "${folder.name}" excluída com sucesso.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbunsCriados(
                      folderName: folder.name,
                      folderId: folder.id,
                      subfolders: folder.subfolders,
                    ),
                    settings: RouteSettings(
                      arguments: {
                        'subfolders': folder.subfolders.map((group) => group.toJson()).toList(),
                      },
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Confirmar Exclusão'),
                                          content: const Text('Tem certeza que deseja excluir esta pasta?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Fecha o diálogo
                                              },
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop(); // Fecha o diálogo
                                                try {
                                                  // Substitua pela sua chamada à API
                                                  // await ApiService.deleteFolder(folder.id);
                                                  setState(() {
                                                    _folders.removeAt(0); // Ajuste para remover a pasta correta
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Pasta excluída via API.'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Erro ao excluir pasta: $e'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Excluir'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                          const Icon(
                          Icons.folder,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          folder.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        if (folder.creationDate != null)
                          Text(
                            folder.creationDate!.toLocal().toString().split(' ')[0],
                            style: const TextStyle(
                              color: Color.fromARGB(108, 255, 255, 255),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],)      
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      Positioned(
        top: 8,
        right: 8,
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmar Exclusão'),
                  content: const Text('Tem certeza que deseja excluir esta pasta?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Fecha o diálogo
                      },
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Fecha o diálogo
                        try {
                          // Substitua pela sua chamada à API
                          // await ApiService.deleteFolder(folder.id);
                          setState(() {
                            _folders.removeAt(0); // Ajuste para remover a pasta correta
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Pasta excluída via API.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao excluir pasta: $e'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('Excluir'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    ],
  ),
),
                  const SizedBox(height: 10),
                ],
              ),
            ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  "assets/logo_cortada.png",
                  width: 150,
                  height: 50,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50, top: 8, right: 5),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.black),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {
                  _showErrorDialog('Perfil do Usuário');
                },
                title: const Row(children: [
                  Icon(Icons.person, color: Color(0xFFaed513)),
                  SizedBox(width: 18),
                  Text('Perfil')
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {},
                title: const Row(children: [
                  Icon(Icons.card_membership, color: Color(0xFFaed513)),
                  SizedBox(width: 15),
                  Text('Financeiro')
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {
                  if (UserHelper.instance.user?.idPlano == 1) {
                    return;
                  }
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => const DialogRanking(),
                  );
                },
                title: const Row(children: [
                  Icon(Icons.call_split_sharp, color: Color(0xFFaed513)),
                  SizedBox(width: 15),
                  Text('Ranking')
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {},
                title: const Row(children: [
                  Icon(
                    Icons.analytics,
                    color: Color(0xFFaed513),
                  ),
                  SizedBox(width: 15),
                  Text('Dados de Uso')
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {},
                title: const Row(children: [
                  Icon(Icons.settings, color: Color(0xFFaed513)),
                  SizedBox(width: 15),
                  Text('Configurações')
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}