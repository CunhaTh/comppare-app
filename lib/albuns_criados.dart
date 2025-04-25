import 'package:application_progress/principal.dart';
import 'package:application_progress/views/compparepage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:html' as html;


class AlbunsCriados extends StatefulWidget {
final List<Uint8List> images;
final String folderName; 
const AlbunsCriados({super.key, required this.images, required this.folderName,});
 
  @override
  State<AlbunsCriados> createState() => _AlbunsCriados();
}

class ImageItem {
  final Uint8List imageData;
  final String subAlbumName;

  ImageItem({required this.imageData, required this.subAlbumName});
}
class SubAlbum {
  final String name;
  final List<ImageItem> images;

  SubAlbum({required this.name, required this.images});
}

class _AlbunsCriados extends State<AlbunsCriados> {
  final ImagePicker _picker = ImagePicker();
   List<SubAlbum> subAlbums = [];
  List<Folder> _folders = [];

 List<ImageItem> savedItems = [];

  void _showSaveDialog(Uint8List imageData) {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Salvar Imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nome do Subálbum'),
              ),
              SizedBox(height: 10),
              Text('Deseja salvar a imagem com esse nome?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                String name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    // Verifica se já existe um subálbum com esse nome
                    SubAlbum? existing = subAlbums.firstWhere(
                      (sub) => sub.name == name,
                      orElse: () => SubAlbum(name: name, images: []),
                    );

                    if (subAlbums.contains(existing)) {
                      // Adiciona a imagem ao subálbum existente
                      existing.images.add(
                        ImageItem(imageData: imageData, subAlbumName: name),
                      );
                    } else {
                      // Cria um novo subálbum e adiciona a imagem
                      subAlbums.add(
                        SubAlbum(
                          name: name,
                          images: [
                            ImageItem(imageData: imageData, subAlbumName: name),
                          ],
                        ),
                      );
                    }
                  });
                  Navigator.of(context).pop();
                } else {
                  // Opcional: mostrar mensagem de erro
                }
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }



Future<void> _addMultipleImages() async {
  String subAlbumName = '';

  // Função para solicitar o nome do subálbum
  Future<String?> _promptSubAlbumName() async {
    TextEditingController _controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nome do Subálbum'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Digite o nome do subálbum'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(_controller.text.trim());
                } else {
                  // Opcional: exibir mensagem de erro
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  if (kIsWeb) {
    // Web: permite selecionar múltiplos arquivos
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..multiple = true;
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      for (var file in files) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoadEnd.first; // aguarda leitura
        final data = reader.result;
        if (data != null) {
          // Antes de salvar, solicitar o nome do subálbum
          String? name = await _promptSubAlbumName();
          if (name != null && name.isNotEmpty) {
            setState(() {
              savedItems.add(ImageItem(imageData: data as Uint8List, subAlbumName: name));
            });
          }
        }
      }
    });
  } else {
    // Mobile: usar pickMultiImage
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        final bytes = await File(image.path).readAsBytes();
        // Antes de salvar, solicitar o nome do subálbum
        String? name = await _promptSubAlbumName();
        if (name != null && name.isNotEmpty) {
          setState(() {
            savedItems.add(ImageItem(imageData: bytes, subAlbumName: name));
          });
        }
      }
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
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Icon(Icons.logout),
          ),
        ),
      ],
    ),
    body: Stack(
      children: [
        Column(
          children: [
            // Exibe informações do álbum
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do álbum
                  Row(
                    children: [
                      Text('Album:  ', style: TextStyle(color: Colors.black, fontSize: 15)),
                      Container(
                        height: 30,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFFaed513),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30, top: 5),
                          child: Text(
                            '${widget.folderName}',
                            style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Grid de imagens
           Expanded(
  child: GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, // 2 colunas
      crossAxisSpacing: 16, // espaçamento horizontal entre os itens
      mainAxisSpacing: 8, // espaçamento vertical entre os itens
      childAspectRatio: 0.95, // ajusta a proporção do card (ajuste se necessário)
    ),
    itemCount: savedItems.length,
    itemBuilder: (context, index) {
      final item = savedItems[index];
      return Card(
        color: const Color.fromARGB(255, 223, 223, 223),
        margin: EdgeInsets.all(8), // pode ajustar para manter espaçamento
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.memory(
                item.imageData,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.subAlbumName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    },
  ),
)


          ],
        ),
        // Botão fixo na parte inferior
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () async {
                            await _addMultipleImages();
                            }
,
            child: Icon(Icons.add),
            tooltip: 'Adicionar Imagem',
          ),
        ),
      ],
    ),
  );
}



}


