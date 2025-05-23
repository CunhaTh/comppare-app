import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Remover se não for mais necessário

void main() {
  runApp(MyApp());
}

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

class Folder {
  final String name;
  final DateTime creationDate;
  final String category;

  Folder({required this.name, required this.category})
      : creationDate = DateTime.now();
}

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  final List<Folder> _folders = [];
  String _searchQuery = '';

  TextEditingController folderNameController = TextEditingController();
  String selectedCategory = 'Categoria 1';
  List<String> categories = ['Categoria 1', 'Categoria 2', 'Categoria 3'];

  void _addFolder(String folderName, String selectedCategory) {
    setState(() {
      _folders.add(Folder(
        name: folderName,
        category: selectedCategory,
      ));
    });
  }

  Future<void> _showAModal() async {
    final TextEditingController folderNameController =
        TextEditingController();
    String selectedCategory = categories[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Album'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: folderNameController,
                  decoration: const InputDecoration(hintText: "Nome da Pasta"),
                ),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                  items: categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10)
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

                  // Navegar para a página CompparePage com as informações da pasta
                  
                
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira um nome para a pasta.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        padding: const EdgeInsets.only(),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Column(
            children: [
              const SizedBox(height: 49),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _showAModal,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: const Color(0xFFaed513),
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    ),
                    child: Icon(Icons.add_a_photo, size: 50),
                  ),
                  GestureDetector(
                    onTap: _showAModal,
                    child: const Text(
                      'Aperte aqui para criar um novo álbum',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      // O Drawer pode ser mantido ou removido, dependendo das suas necessidades
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
            // Outros itens do Drawer...
          ],
        ),
      ),
    );
  }
}
