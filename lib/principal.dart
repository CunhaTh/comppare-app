import 'package:application_progress/views/compparepage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Remover se não for mais necessário
 // Certifique-se de que o caminho do arquivo está correto

void main() {
  runApp(MyApp());
}

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
  final String category;

  Folder({required this.name, required this.category})
      : creationDate = DateTime.now();
}

class PrincipalPage extends StatefulWidget {
  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  List<Folder> _folders = [];
  String _searchQuery = '';
  final TextEditingController folderNameController = TextEditingController();
  String selectedCategory = 'Categoria 1';
  List<String> categories = [
    'Categoria 1',
    'Categoria 2',
    'Categoria 3'
  ];

  void _addFolder(String folderName, String selectedCategory) {
    setState(() {
      _folders.add(Folder(name: folderName, category: selectedCategory));
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

  Future<void> _showAModal() async {
    String selectedCategory = categories[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Criar Album'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: folderNameController,
                  decoration: InputDecoration(hintText: "Nome da Pasta"),
                ),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                  items: categories
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  _addFolder(folderName, selectedCategory);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor, insira um nome para a pasta.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            SizedBox(height: 30,),
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
            Expanded(
              child: ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_folders[index].name, style: TextStyle(color: Colors.white),),
                    subtitle: Text(_folders[index].category,style: TextStyle(color: const Color.fromARGB(108, 255, 255, 255))),
                    onTap: () {
                      // Navegar para a CompparePage ao clicar na pasta
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompparePage(
                            folderName: _folders[index].name,
                            category: _folders[index].category, images: [],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
             SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 100),
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
            // Outros itens do Drawer...
          ],
        ),
      ),
    );
  }
}
