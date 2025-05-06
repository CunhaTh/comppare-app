import 'dart:convert';
import 'package:application_progress/albuns_criados.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'dialog_ranking.dart';
import 'chat_button.dart'; // Remover se não for mais necessário
// Certifique-se de que o caminho do arquivo está correto

class MyApp extends StatelessWidget {
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

class Folder {
  final String name;
  final DateTime creationDate;

  Folder({required this.name}) : creationDate = DateTime.now();
}

class PrincipalPage extends StatefulWidget {
  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  List<Folder> _folders = [];
  String _searchQuery = '';
  final TextEditingController folderNameController = TextEditingController();

  void _addFolder(String folderName, DateTime dateTime) {
    setState(() {
      // Altere a chamada do método no onPressed
      if (folderName.isNotEmpty) {
        _folders.add(Folder(name: folderName));
      }
    });

    // Chame a função para criar a pasta no servidor
    _createFolder(folderName).then((_) {
      // Sucesso ao criar no servidor
      print('Pasta criada no servidor.');
    }).catchError((error) {
      // Em caso de erro
      _showErrorDialog('Erro ao criar pasta: $error');
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perfil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _createFolder(
    String folderName,
  ) async {
    final url = Uri.parse("https://api.comppare.com.br/api/pasta/create");

    final int userId = 1;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idUsuario': userId,
        'nomePasta': '$folderName',
      }),
    );

    if (response.statusCode == 200) {
      print('Pasta criada com sucesso!');
    } else {
      // Em caso de erro
      throw Exception('Falha ao criar pasta: ${response.body}');
    }
  }

  Future<void> _showAModal() async {
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Criar Álbum'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: folderNameController,
                  decoration: InputDecoration(hintText: "Nome do Album"),
                ),
                TextButton(
                  onPressed: () async {
                    // Selecionar data
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
                        : 'Selecionar Data',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty && selectedDate != null) {
                  _addFolder(folderName, selectedDate!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Por favor, insira um nome para a pasta e selecione uma data.')),
                  );
                }
              },
              child: Text('Salvar'),
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
          title: Text('SubAlbum Criado'),
          content: SingleChildScrollView(
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
              child: Text('Ok'),
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
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _showAModal,
                  child: Icon(Icons.add_sharp, size: 25),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Color(0xFFaed513),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  ),
                ),
                GestureDetector(
                  onTap: _showAModal,
                  child: Text(
                    '''   Aperte  aqui 
     para  criar 
 um novo álbum''',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 80,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text('Albuns Criados',
                  style: TextStyle(color: Colors.white, fontSize: 30)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value; // Atualiza a consulta de busca
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar pastas...',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Navegar para a CompparePage ao clicar na pasta
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbunsCriados(
                            folderName: _folders[index].name,
                            images: [],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.grey[900], // cor de fundo do card
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Ícone acima do nome
                            Icon(
                              _folders[index].creationDate == 'imagem'
                                  ? Icons.image
                                  : Icons.folder,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              _folders[index].name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _folders[index].name,
                              style: TextStyle(
                                color: Color.fromARGB(108, 255, 255, 255),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
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
                    child: CircleAvatar(
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
            Divider(color: Colors.black),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                onTap: () {
                  _showErrorDialog('Perfil do Usuário');
                },
                title: Row(children: [
                  Icon(
                    Icons.person,
                    color: Color(0xFFaed513),
                  ),
                  SizedBox(width: 18),
                  Text('Perfil')
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                /*Adicione a navegação da pagina */
                onTap: () {},
                title: Row(children: [
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
                title: Row(children: [
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
                title: Row(children: [
                  Icon(Icons.support_agent_outlined, color: Color(0xFFaed513)),
                  SizedBox(width: 15),
                  Text('Suporte')
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                /*Adicione a navegação da pagina */
                onTap: () {},
                title: Row(children: [
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
                /*Adicione a navegação da pagina */
                onTap: () {},
                title: Row(children: [
                  Icon(
                    Icons.settings,
                    color: Color(0xFFaed513),
                  ),
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
