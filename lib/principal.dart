import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:html' as html;

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
  final List<Uint8List> images;
  final DateTime creationDate;
  final String category;

  Folder({required this.name, required this.images, required this.category})
      : creationDate = DateTime.now();
}

class PrincipalPage extends StatefulWidget {
  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  List<Uint8List> _images = [];
  List<Folder> _folders = [];
  final ImagePicker _picker = ImagePicker();
  String _searchQuery = '';

  TextEditingController folderNameController = TextEditingController();
  String selectedCategory = 'Categoria 1';
  List<String> categories = ['Categoria 1', 'Categoria 2', 'Categoria 3'];

  void _addFolder(String folderName, String selectedCategory) {
    if (_images.isNotEmpty) {
      setState(() {
        _folders.add(Folder(
          name: folderName,
          images: List.from(_images),
          category: selectedCategory,
        ));
        _images.clear(); // Limpa as imagens após criar uma pasta
      });
    }
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
    final TextEditingController folderNameController = TextEditingController();
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
                  items: categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addImage,
                  child: Text('Selecionar Imagem'),
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

  Future<void> _addImage() async {
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(files[0]);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _images.add(reader.result as Uint8List);
          });
        });
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path).readAsBytesSync());
        });
      }
    }
  }

  void _compareImages(List<Uint8List> images) {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Esta pasta não contém imagens.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonPage(images: images),
      ),
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
        actions: [
          Builder(
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrincipalPage(),
                      ),
                    );
                  },
                  child: Icon(Icons.logout),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(),
        child: Container(
          decoration: BoxDecoration(
          color: Colors.black,
        ),
          child: Column(
            children: [
              SizedBox(height: 49,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                ElevatedButton(
                onPressed: _showAModal,
                child: Icon(Icons.add_a_photo, size: 50,),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Color(0xFFaed513),
                                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                                    ),
                                   ),
                             GestureDetector(
                              onTap: _showAModal,
                              child: Text(
                                '''   Aperte aqui 
  para criar um 
   novo álbum''',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
              ],),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _images.map((image) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.memory(image, width: 50, height: 100),
                  );
                }).toList(),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_folders[index].name,style: TextStyle(color: Colors.white),),
                      onTap: () => _compareImages(_folders[index].images),
                    );
                  },
                ),
              ),
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
              padding: const EdgeInsets.only(
                  left: 50, top: 8, right: 5),
              child: GestureDetector(
                onTap: (){
                  Navigator.of(context).pop();
                },
                child: CircleAvatar(
                    backgroundColor: Colors.black,
                    child:Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),),
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
              Icon(Icons.person,color: Color(0xFFaed513),),
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
            onTap: () {},
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
              Icon(Icons.analytics, color: Color(0xFFaed513),),
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
              Icon(Icons.settings, color: Color(0xFFaed513),),
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




class ComparisonPage extends StatelessWidget {
  final List<Uint8List> images;

  ComparisonPage({required this.images});

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
        actions: [
          Builder(
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrincipalPage(),
                      ),
                    );
                  },
                  child: Icon(Icons.logout),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // GridView para exibir as imagens
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                child: Image.memory(
                  images[index],
                  scale: 15,
                ),
              );
            },
          ),
          // Container fixo na parte inferior com o botão "COMPPARE"
          Positioned(
            left: 15,
            right: 15,
            bottom: 40,
            child: Container(
              color: Colors.black, // Cor de fundo do container
              padding: EdgeInsets.only(top: 15, bottom: 15), // Espaçamento interno
              child: GestureDetector(
                onTap: () {
                  _showComparisonDialog(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('COMPPARE', style: TextStyle(color: Colors.white),),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 30,)
        ],
      ),
    );
  }

  void _showComparisonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(children: [
                     Text("Comparação", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                     Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      SizedBox(height: 20),
                // Exibe a primeira imagem
                      Image.memory(images.first, scale: 15),
                      SizedBox(height: 50,width: 30,),
                      // Exibe a última imagem
                      Image.memory(images.last, scale: 15),
                     ],)
                
                ],)
             
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Fechar"),
            ),
          ],
        );
      },
    );
  }
}

