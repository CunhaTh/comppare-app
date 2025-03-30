import 'package:application_progress/main.dart';
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
   String _searchQuery = '';



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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 80),
              child: GestureDetector(
                  onTap: (){
                    Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyHomePage(title: '',),
                                ),
                              );
                              },
                              child: Image.asset(
                                  "assets/logo_cortada.png",
                                  width: 150,
                                  height: 50,
                                ),
                                ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 450),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 30,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pasta 1',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),), Image.asset('assets/logo_escura.png',scale: 6,)
                ],
              ),
              SizedBox(height: 20,),
              Container(
                width: 320,
                height: 40,
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
                                  borderSide: BorderSide(color: Colors.white,),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                            ),
              ),
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
                style: ElevatedButton.styleFrom(
        foregroundColor: Color.fromARGB(255, 251, 255, 250),
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textStyle: TextStyle(fontSize: 16),
      ),
                onPressed: () => _compareImages(context),
                child: Text('Comparar Fotos',style: TextStyle(color: Colors.white),),
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
