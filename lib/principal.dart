import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data'; // Para usar o Uint8List
import 'dart:html' as html; // Para usar no Flutter Web

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comparação de Projetos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  List<Uint8List?> _images = [null, null]; // Alterado para armazenar duas imagens
  final ImagePicker _picker = ImagePicker();

  Future<void> _addImage(int index) async {
    // Se estiver no Web, use o file picker do HTML
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
            _images[index] = reader.result as Uint8List;
          });
        });
      });
    } else {
      // Para dispositivos móveis
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _images[index] = File(pickedFile.path).readAsBytesSync();
        });
      }
    }
  }

  void _compareImages(BuildContext context) {
    if (_images.where((image) => image != null).length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicione pelo menos duas fotos para comparar')),
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
    // Exemplo simples de "salvar" as imagens
    for (var image in _images) {
      if (image != null) {
        print('Imagem salva: [bytes: ${image.length}]'); // Exibir tamanho da imagem
        // Aqui você pode adicionar o código para salvar no banco de dados
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
        title: Text('Page Principal'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 450),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(children: [
                    Text('Adicionar Imagem', style: TextStyle(fontSize: 30)),
                    Center(
                      child: GestureDetector(
                        child: IconButton(
                          onPressed: () => _addImage(0), // Adiciona imagem à primeira posição
                          icon: _images[0] != null
                              ? Image.memory(_images[0]!, width: 150, height: 150) // Usando Image.memory
                              : Icon(Icons.upload_file, size: 150, color: Colors.green),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: _saveImages,
                      child: Text('Salvar'),
                    ),
                  ]),

                  SizedBox(width: 250),
                  Column(children: [
                    Text('Campo Pesquisa', style: TextStyle(fontSize: 30)),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            child: IconButton(
                              onPressed: () => _addImage(1), // Adiciona imagem à segunda posição
                              icon: _images[1] != null
                                  ? Image.memory(_images[1]!, width: 80, height: 80) // Usando Image.memory
                                  : Icon(Icons.upload_file, size: 80),
                            ),
                          ),
                          GestureDetector(
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.paste_outlined, size: 80),
                            ),
                          ),
                          GestureDetector(
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.paste_outlined, size: 80),
                            ),
                          ),
                          GestureDetector(
                            child: IconButton(
                              onPressed: () {
                                _compareImages(context);
                              },
                              icon: Icon(
                                Icons.add_box_rounded,
                                size: 80,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),
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
        title: Text('Comparar Fotos'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Image.memory(images[0]),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Image.memory(images[1]),
          ),
        ],
      ),
    );
  }
}
