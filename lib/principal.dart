import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

class PrincipalPage extends StatefulWidget {
  @override
  _PrincipalPage createState() => _PrincipalPage();
}

class _PrincipalPage extends State<PrincipalPage> {
  List<Uint8List?> _images = []; // Permitir lista de imagens
  List<Uint8List?> _savedImages = []; // Lista para armazenar imagens salvas
  final ImagePicker _picker = ImagePicker();

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

  void _compareImages(BuildContext context) {
    if (_images.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicione pelo menos dez fotos para comparar')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonPage(images: _images.where((image) => image != null).cast<Uint8List>().toList()),
      ),
    );
  }

  void _saveImages() {
    for (var image in _images) {
      if (image != null) {
        setState(() {
          _savedImages.add(image); // Adiciona a imagem à lista de imagens salvas
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imagens salvas com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo_cortada.png",
              width: 150,
              height: 50,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        actions: [
      // Novo IconButton para abrir o Drawer
      Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () {
                      // Abre o modal ao invés do Drawer
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: 300, // Altura do modal
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Perfil',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 20),
                                ListTile(
                                  leading: Icon(Icons.person),
                                  title: Text('Meu Perfil'),
                                  onTap: () {
                                    // Ação ao clicar em "Meu Perfil"
                                    Navigator.pop(context); // Fecha o modal
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.settings),
                                  title: Text('Configurações'),
                                  onTap: () {
                                    // Ação ao clicar em "Configurações"
                                    Navigator.pop(context); // Fecha o modal
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.logout),
                                  title: Text('Sair'),
                                  onTap: () {
                                    // Ação ao clicar em "Sair"
                                    Navigator.pop(context); // Fecha o modal
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Image.asset(
                      'assets/profile.jpg',
                      scale: 20,
                    ),
                  ),
                );
              },
            ),
        ],
  ),
  body: Container(
      decoration: BoxDecoration(
        color: Colors.black, // Cor de fundo
        // Se você quiser adicionar uma imagem de fundo, use:
        // image: DecorationImage(
        //   image: AssetImage("assets/background_image.png"),
        //   fit: BoxFit.cover,
        // ),
      ),
    child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: ElevatedButton(
                      onPressed: _addImage,
                      child: GestureDetector(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 60,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor:
                            Color(0xFFaed513),
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                      ),
                    ),
                  ),
                 
                  Text(''' Aperte aqui
para criar um
  novo album ''',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white)),
                  
                  ],),
                 
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: _images.map((image) {
                      return image != null
                          ? Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.memory(image,
                                  width: 100, height: 100),
                            )
                          : Container(width: 100, height: 100, color: Colors.grey);
                    }).toList(),
                  ),
                  SizedBox(height: 150),
                  ElevatedButton(
                    onPressed: _saveImages,
                    child: Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor:
                          Color.fromARGB(255, 251, 255, 250),
                      backgroundColor: Color(0xFFaed513),
                      padding:
                          EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Pastas do Usuário',
                          style: TextStyle(
                              fontSize: 30, color: Colors.white70)),
                      Center(
                        child: Container(
                          height: 200, // Defina uma altura para o ListView
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _savedImages.length,
                            itemBuilder: (context, index) {
                              return _savedImages[index] != null
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Image.memory(
                                            _savedImages[index]!,
                                            width: 100,
                                            height: 100),
                                      ),
                                    )
                                  : Container(
                                      width: 100, height: 100, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _compareImages(context);
              },
              child: Text('COMPARAR'),
              style: ElevatedButton.styleFrom(
                foregroundColor:
                    Colors.white,
                backgroundColor:
                    Color(0xFFaed513),
                padding:
                    EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                textStyle: TextStyle(fontSize: 18),
              ),
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
              padding: const EdgeInsets.only(
                  left: 50, top: 8, right: 5),
              child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 25,
                    ),
                  )),
            ),
          ],
        ),
        Divider(color: Colors.black),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            onTap: () {},
            title: Row(children: [
              Icon(Icons.analytics),
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
              Icon(Icons.card_membership),
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
              Icon(Icons.call_split_sharp),
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
              Icon(Icons.support_agent_outlined),
              SizedBox(width: 15),
              Text('Suporte')
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
        title: Text('Comparando Fotos', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF637700),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 80,
            child: Image.memory(images[0]),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Image.memory(images[1]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[2]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[3]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[4]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[5]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[6]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[7]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[8]),
          ),
          SizedBox(
            width: 80,
            child: Image.memory(images[9]),
          ),
        ],
      ),
    );
  }
}
