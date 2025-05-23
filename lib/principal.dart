import 'dart:convert';
import 'package:application_progress/albuns_criados.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'dialog_ranking.dart';
import 'chat_button.dart'; 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comparação de Projetos',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: PrincipalPage(),
    );
  }
}



class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class Folder {
  final String name;
  final DateTime? creationDate; 

  Folder({required this.name, this.creationDate});
}

class _PrincipalPageState extends State<PrincipalPage> {
  final List<Folder> _folders = [];
  String _searchQuery = '';
  final TextEditingController folderNameController = TextEditingController();

  void _addFolder(String folderName, DateTime? dateTime) {
    setState(() {
      if (folderName.isNotEmpty) {
        _folders.add(Folder(name: folderName, creationDate: dateTime));
      }
    });

   
    _createFolder(folderName).then((createdFolder) {
     
      setState(() {
        final index = _folders.indexWhere((folder) => folder.name == folderName);
        if (index != -1 && createdFolder != null) {
          _folders[index] = createdFolder;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasta criada com sucesso!')),
      );
    }).catchError((error) {
      _showErrorDialog('Erro ao criar pasta: $error');
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
  final url = Uri.parse("https://api.comppare.com.br/api/pasta/delete");
  const int userId = 2;

  try {
    final response = await http.post( // Use http.delete se o endpoint for DELETE
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idUsuario': userId,
        'nomePasta': folderName,
      }),
    );

    if (response.statusCode == 200) {
      // Exclusão bem-sucedida
      return;
    } else {
      throw Exception('Falha ao excluir pasta: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erro na requisição: $e');
  }
}

  Future<Folder?> _createFolder(String folderName) async {
    final url = Uri.parse("https://api.comppare.com.br/api/pasta/create");
    const int userId = 2;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idUsuario': userId,
          'nomePasta': folderName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] != null) {
          final folderData = data['data'] as Map<String, dynamic>;
          final creationDate = folderData['dataCriacao'] != null
              ? DateTime.parse(folderData['dataCriacao'] as String)
              : null;
          return Folder(name: folderName, creationDate: creationDate);
        }
        return Folder(name: folderName); // Retorna sem data se não houver
      } else {
        throw Exception('Falha ao criar pasta: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
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
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Image.asset(
                "assets/logo_cortada.png",
                width: 150,
                height: 50,
              ),
            )
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
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
              child: ListView.builder(
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
                      setState(() {
                        _folders.removeAt(index);
                      });
                      try {
                        await _deleteFolder(folder.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pasta "${folder.name}" excluída com sucesso.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          _folders.insert(index, folder);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao excluir pasta: $e'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbunsCriados(
                              folderName: folder.name,
                              images: const [],
                            ),
                          ),
                        );
                      },
                      child: Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), // Small margin for better spacing
                      child: Padding(
                        padding: const EdgeInsets.all(16), // Consistent padding for better layout
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9, // 80% of screen width
                          height: MediaQuery.of(context).size.height * 0.1, // Full screen height
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
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
                                textAlign: TextAlign.center, // Ensure text is centered
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                  );
                },
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
                  Icon(Icons.support_agent_outlined, color: Color(0xFFaed513)),
                  SizedBox(width: 15),
                  Text('Suporte')
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {},
                title: const Row(children: [
                  Icon(Icons.analytics, color: Color(0xFFaed513)),
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