import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
      home: ProjectComparisonPage(),
    );
  }
}

class ProjectComparisonPage extends StatefulWidget {
  @override
  _ProjectComparisonPageState createState() => _ProjectComparisonPageState();
}

class _ProjectComparisonPageState extends State<ProjectComparisonPage> {
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();



  void _compareImages(BuildContext context) {
    if (_images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicione pelo menos duas fotos para comparar')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonPage(images: _images),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comparação de Projetos'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 450),
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Image.file(
                      _images[index],
                      height: 150,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              
              ElevatedButton(
                onPressed: () => _compareImages(context),
                child: Text('Comparar Fotos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ImagePicker {
  getImage({required ImageSource source}) {}
}

class ComparisonPage extends StatelessWidget {
  final List<File> images;

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
            child: Image.file(images[0]),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Image.file(images[1]),
          ),
        ],
      ),
    );
  }
}
