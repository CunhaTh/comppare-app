import 'dart:typed_data';
import 'package:application_progress/main.dart';
import 'package:application_progress/principal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:application_progress/views/compparepage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;


class CompparePage extends StatefulWidget {
  final List<Uint8List> images;

  CompparePage({required this.images, required String category, required String folderName});

  @override
  State<CompparePage> createState() => _CompparePageState();
}

class _CompparePageState extends State<CompparePage> {
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
          widget.images.add(reader.result as Uint8List);
        });
      });
    });
  } else {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        widget.images.add(File(pickedFile.path).readAsBytesSync());
      });
    }
  }
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
      body: Stack(
        children: [
          // GridView para exibir as imagens
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
            ),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Container(
                child: Image.memory(
                  widget.images[index],
                  scale: 15,
                ),
              );
            },
          ),
           Positioned(
          left: 15,
          right: 10,
          bottom: 400,
          child: FloatingActionButton(
            backgroundColor:Color(0xFFaed513),
            onPressed: _addImage,
            child: Icon(Icons.add_a_photo,color: Colors.black,),
          ),
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
                      Image.memory(widget.images.first, scale: 15),
                      SizedBox(height: 50,width: 30,),
                      // Exibe a última imagem
                      Image.memory(widget.images.last, scale: 15),
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