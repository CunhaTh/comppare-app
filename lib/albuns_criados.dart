import 'package:application_progress/principal.dart';
import 'package:application_progress/views/comppareimg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:html' as html;

class AlbunsCriados extends StatefulWidget {
  final List<Uint8List> images;
  final String folderName;
  const AlbunsCriados({super.key, required this.images, required this.folderName});

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

class SubAlbumData {
  final String name;
  final List<String> tags;

  SubAlbumData({required this.name, required this.tags});
}

class ImageGroup {
  final String subAlbumName;
  final List<ImageItem> images;
  List<String> tags;

  ImageGroup({
    required this.subAlbumName,
    required this.images,
    this.tags = const [],
  });
}

class _AlbunsCriados extends State<AlbunsCriados> {
  final ImagePicker _picker = ImagePicker();
  List<SubAlbum> subAlbums = [];
  List<Folder> _folders = [];
  List<ImageGroup> imageGroups = [];

  void _showSaveDialog(Uint8List imageData) {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar Imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Subálbum'),
              ),
              const SizedBox(height: 10),
              const Text('Deseja salvar a imagem com esse nome?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                String name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    SubAlbum? existing = subAlbums.firstWhere(
                      (sub) => sub.name == name,
                      orElse: () => SubAlbum(name: name, images: []),
                    );

                    if (subAlbums.contains(existing)) {
                      existing.images.add(
                        ImageItem(imageData: imageData, subAlbumName: name),
                      );
                    } else {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome do subálbum não pode estar vazio.')),
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

  Future<SubAlbumData?> _promptSubAlbumName() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController tagsController = TextEditingController();

    return showDialog<SubAlbumData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nome do Subálbum'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Digite o nome do subálbum',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Digite as tags (separadas por vírgula)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  List<String> tags = tagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();
                  Navigator.of(context).pop(SubAlbumData(
                    name: nameController.text.trim(),
                    tags: tags,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome do subálbum não pode estar vazio.')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMultipleImages() async {
    SubAlbumData? subAlbumData;
    List<Uint8List> savedImages = [];

    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..multiple = true;
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) return;

        if (subAlbumData == null) {
          subAlbumData = await _promptSubAlbumName();
          if (subAlbumData == null || subAlbumData!.name.isEmpty) {
            return;
          }
        }

        List<ImageItem> newImages = [];

        for (var file in files) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;
          final data = reader.result;
          if (data != null && data is Uint8List) {
            newImages.add(ImageItem(imageData: data, subAlbumName: subAlbumData!.name));
          }
        }

        setState(() {
          imageGroups.add(ImageGroup(
            subAlbumName: subAlbumData!.name,
            images: newImages,
            tags: subAlbumData!.tags,
          ));
        });
      });
    } else {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        if (subAlbumData == null) {
          subAlbumData = await _promptSubAlbumName();
          if (subAlbumData == null || subAlbumData!.name.isEmpty) {
            return;
          }
        }

        List<ImageItem> newImages = [];

        for (var image in images) {
          final bytes = await File(image.path).readAsBytes();
          newImages.add(ImageItem(imageData: bytes, subAlbumName: subAlbumData!.name));
        }

        setState(() {
          imageGroups.add(ImageGroup(
            subAlbumName: subAlbumData!.name,
            images: newImages,
            tags: subAlbumData!.tags,
          ));
        });
      }
    }
  }

Future<void> _editSubAlbum(int groupIndex) async {
    TextEditingController tagsController = TextEditingController(
      text: imageGroups[groupIndex].tags.join(', '),
    );
    List<ImageItem> newImages = [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Subálbum'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão para adicionar fotos
                    if (kIsWeb)
                      ElevatedButton(
                        onPressed: () {
                          html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
                            ..multiple = true;
                          uploadInput.accept = 'image/*';
                          uploadInput.click();

                          uploadInput.onChange.listen((e) async {
                            final files = uploadInput.files;
                            if (files != null && files.isNotEmpty) {
                              for (var file in files) {
                                final reader = html.FileReader();
                                reader.readAsArrayBuffer(file);
                                await reader.onLoadEnd.first;
                                final data = reader.result;
                                if (data != null && data is Uint8List) {
                                  setState(() {
                                    newImages.add(ImageItem(
                                      imageData: data,
                                      subAlbumName: imageGroups[groupIndex].subAlbumName,
                                    ));
                                  });
                                }
                              }
                            }
                          });
                        },
                        child: const Text('Adicionar Fotos (Web)'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          final List<XFile>? images = await _picker.pickMultiImage();
                          if (images != null && images.isNotEmpty) {
                            for (var image in images) {
                              final bytes = await File(image.path).readAsBytes();
                              setState(() {
                                newImages.add(ImageItem(
                                  imageData: bytes,
                                  subAlbumName: imageGroups[groupIndex].subAlbumName,
                                ));
                              });
                            }
                          }
                        },
                        child: const Text('Adicionar Fotos (Mobile)'),
                      ),
                    const SizedBox(height: 16),
                    // Pré-visualização das novas imagens
                    if (newImages.isNotEmpty) ...[
                      const Text(
                        'Novas Imagens:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 150, // Limita a altura da pré-visualização
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: newImages.map((image) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      image.imageData,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            newImages.remove(image);
                                          });
                                        },
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Campo para editar tags
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Editar tags (separadas por vírgula)',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                newImages.clear();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> updatedTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                setState(() {
                  imageGroups[groupIndex].images.addAll(newImages);
                  imageGroups[groupIndex].tags = updatedTags;
                });
                Navigator.of(context).pop();
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Album:  ', style: TextStyle(color: Colors.black, fontSize: 15)),
                        Container(
                          height: 30,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFaed513),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 30, top: 5),
                            child: Text(
                              '${widget.folderName}',
                              style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GestureDetector(
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: imageGroups.length,
                              itemBuilder: (context, index) {
                                final group = imageGroups[index];
                                return ImageGroupWidget(
                                  group: group,
                                  onEdit: () => _editSubAlbum(index),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    if (imageGroups.isNotEmpty) {
                      final selectedGroup = imageGroups[0];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImagemDetalhesPage(
                            images: selectedGroup.images.map((img) => img.imageData).toList(),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 220,
            right: 220,
            bottom: 120,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFaed513),
              onPressed: () async {
                await _addMultipleImages();
              },
              child: const Icon(
                Icons.add_a_photo,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageGroupWidget extends StatefulWidget {
  final ImageGroup group;
  final VoidCallback onEdit;

  const ImageGroupWidget({Key? key, required this.group, required this.onEdit}) : super(key: key);

  @override
  State<ImageGroupWidget> createState() => _ImageGroupWidgetState();
}

class _ImageGroupWidgetState extends State<ImageGroupWidget> {
  // Função para adicionar mais tags
  Future<void> _addMoreTags(BuildContext context) async {
    TextEditingController tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Tags'),
          content: TextField(
            controller: tagsController,
            decoration: const InputDecoration(
              labelText: 'Digite novas tags (separadas por vírgula)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> newTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                setState(() {
                  // Adiciona novas tags à lista existente, evitando duplicatas
                  widget.group.tags.addAll(newTags.where((tag) => !widget.group.tags.contains(tag)));
                });
                Navigator.of(context).pop();
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Card(
          color: const Color.fromARGB(255, 223, 223, 223),
          margin: const EdgeInsets.all(12).copyWith(top: 30),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.group.images.length == 1) ...[
                Expanded(
                  child: Image.memory(
                    widget.group.images.first.imageData,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.group.tags.isNotEmpty)
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 4.0,
                                children: widget.group.tags.map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Colors.grey[300],
                                    )).toList(),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFFaed513)),
                            onPressed: () => _addMoreTags(context),
                            tooltip: 'Adicionar mais tags',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFaed513),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: widget.onEdit,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Adicionar', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.add),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: widget.group.images.length,
                    itemBuilder: (context, index) {
                      final imageItem = widget.group.images[index];
                      return Image.memory(
                        imageItem.imageData,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.group.tags.isNotEmpty)
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 4.0,
                                children: widget.group.tags.map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Colors.grey[300],
                                    )).toList(),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFFaed513)),
                            onPressed: () => _addMoreTags(context),
                            tooltip: 'Adicionar mais tags',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFaed513),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: widget.onEdit,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Adicionar', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.add),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: -15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFaed513),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.group.subAlbumName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}