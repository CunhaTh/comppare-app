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
        scaffoldBackgroundColor: Color.fromARGB(255, 70, 137, 64),
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
        title: Text('Page Principal', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF637700),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Abre o menu lateral
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribui o espaço entre os widgets
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Adicionar Imagem', style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 70, 137, 64))),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addImage,
                      child: GestureDetector(child: Icon(Icons.add_a_photo_rounded, size: 60,),),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color.fromARGB(255, 70, 137, 64), backgroundColor: Color.fromARGB(179, 196, 255, 211),
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      ),
                    ),
                    SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      children: _images.map((image) {
                        return image != null
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.memory(image, width: 100, height: 100),
                              )
                            : Container(width: 100, height: 100, color: Colors.grey);
                      }).toList(),
                    ),
                    SizedBox(height: 150),
                    ElevatedButton(
                      onPressed: _saveImages,
                      child: Text('Salvar'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color.fromARGB(255, 251, 255, 250), backgroundColor: Color(0xFF637700),
                        padding: EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Text('Pastas do Usuário', style: TextStyle(fontSize: 30, color: Colors.white70)),
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
                                          border: Border.all(color: Colors.white, width: 2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Image.memory(_savedImages[index]!, width: 100, height: 100),
                                      ),
                                    )
                                  : Container(width: 100, height: 100, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                    ]),
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
                  foregroundColor: Color.fromARGB(255, 70, 137, 64), backgroundColor: const Color.fromARGB(179, 196, 255, 211),
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                  textStyle: TextStyle(fontSize: 18),
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
            UserAccountsDrawerHeader(
              accountName: Text("Seu Nome"),
              accountEmail: Text("seuemail@exemplo.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text("A", style: TextStyle(fontSize: 40.0)),
              ),
            ),
            ListTile(
              title: Text('Fechar Menu'),
              onTap: () {
                Navigator.of(context).pop(); // Fecha o menu
              },
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
