import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/comppareimg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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
  final DateTime? creationDate;

  ImageGroup({
    required this.subAlbumName,
    required this.images,
    this.tags = const [],
    this.creationDate,
  });
}

class _AlbunsCriados extends State<AlbunsCriados> {
  final ImagePicker _picker = ImagePicker();
  List<SubAlbum> subAlbums = [];
  List<ImageGroup> imageGroups = [];
  bool isLoading = false;

  Future<void> _createSubAlbum(String folderName, String subAlbumName, List<String> tags, List<String> imageUrls) async {
    final url = Uri.parse("https://api.comppare.com.br/api/pasta/create");
    const int userId = 2;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idUsuario': userId,
          'nomePasta': '$folderName/$subAlbumName',
          'tags': tags,
          'imagens': imageUrls,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('A requisição demorou muito para responder.');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] != null) {
          return;
        }
        throw Exception('Dados inválidos retornados pela API: ${response.body}');
      } else {
        throw Exception('Falha ao criar subálbum: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<String> _uploadImage(Uint8List imageData, String subAlbumName) async {
    final url = Uri.parse("https://api.comppare.com.br/api/imagem/upload"); // Ajuste o endpoint conforme sua API
    const int userId = 2;

    try {
      var request = http.MultipartRequest('POST', url)
        ..fields['idUsuario'] = userId.toString()
        ..fields['subAlbumName'] = subAlbumName
        ..files.add(http.MultipartFile.fromBytes(
          'imagem',
          imageData,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        if (data is Map<String, dynamic> && data['data'] != null && data['data']['url'] != null) {
          return data['data']['url'];
        }
        throw Exception('URL da imagem não retornada pela API: $responseBody');
      } else {
        throw Exception('Falha ao fazer upload da imagem: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  Future<void> _addMultipleImages() async {
    SubAlbumData? subAlbumData = await _promptSubAlbumName();
    if (subAlbumData == null || subAlbumData.name.isEmpty) return;

    List<ImageItem> newImages = [];
    List<String> imageUrls = [];

    // Armazenar o BuildContext antes da operação assíncrona
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      isLoading = true;
    });

    try {
      if (kIsWeb) {
        final uploadInput = html.FileUploadInputElement()..multiple = true;
        uploadInput.accept = 'image/*';
        uploadInput.click();

        await uploadInput.onChange.first;
        final files = uploadInput.files;
        if (files == null || files.isEmpty) return;

        for (var file in files) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;
          final data = reader.result;
          if (data != null && data is Uint8List) {
            final imageUrl = await _uploadImage(data, subAlbumData.name);
            newImages.add(ImageItem(
              imageData: data,
              subAlbumName: subAlbumData.name,
            ));
            imageUrls.add(imageUrl);
          }
        }
      } else {
        final List<XFile>? images = await _picker.pickMultiImage();
        if (images == null || images.isEmpty) return;

        for (var image in images) {
          final bytes = await File(image.path).readAsBytes();
          final imageUrl = await _uploadImage(bytes, subAlbumData.name);
          newImages.add(ImageItem(
            imageData: bytes,
            subAlbumName: subAlbumData.name,
          ));
          imageUrls.add(imageUrl);
        }
      }

      if (newImages.isEmpty) return;

      await _createSubAlbum(
        widget.folderName,
        subAlbumData.name,
        subAlbumData.tags,
        imageUrls,
      );

      if (!mounted) return;
      setState(() {
        imageGroups.add(ImageGroup(
          subAlbumName: subAlbumData.name,
          images: newImages,
          tags: subAlbumData.tags,
          creationDate: DateTime.now(),
        ));
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Subálbum e imagens salvos com sucesso!')),
      );
    } catch (error) {
      if (!mounted) return;
      // Logar o erro para depuração
      debugPrint('Erro ao salvar subálbum ou imagens: $error');
      // Garantir que a mensagem de erro seja uma string
      final errorMessage = error.toString().replaceFirst('Exception: ', '');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao salvar subálbum ou imagens: $errorMessage')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSaveDialog(Uint8List imageData) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar Imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
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
              onPressed: () async {
                String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    final imageUrl = await _uploadImage(imageData, name);
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
                    await _createSubAlbum(widget.folderName, name, [], [imageUrl]);
                    Navigator.of(context).pop();
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao salvar subálbum: $error')),
                    );
                  }
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

  Future<void> _addMoreTags(BuildContext context, ImageGroup group) async {
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
              onPressed: () async {
                List<String> newTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                setState(() {
                  group.tags.addAll(newTags.where((tag) => !group.tags.contains(tag)));
                });
                try {
                  await _createSubAlbum(widget.folderName, group.subAlbumName, group.tags, []);
                  Navigator.of(context).pop();
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar tags: $error')),
                  );
                }
              },
              child: const Text('Adicionar'),
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
                    if (kIsWeb)
                      ElevatedButton(
                        onPressed: () async {
                          html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
                            ..multiple = true;
                          uploadInput.accept = 'image/*';
                          uploadInput.click();

                          await uploadInput.onChange.first;
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
                    if (newImages.isNotEmpty) ...[
                      const Text(
                        'Novas Imagens:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 150,
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
              onPressed: () async {
                List<String> updatedTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                List<String> imageUrls = [];
                try {
                  for (var image in newImages) {
                    final imageUrl = await _uploadImage(image.imageData, imageGroups[groupIndex].subAlbumName);
                    imageUrls.add(imageUrl);
                  }
                  setState(() {
                    imageGroups[groupIndex].images.addAll(newImages);
                    imageGroups[groupIndex].tags = updatedTags;
                  });
                  await _createSubAlbum(
                    widget.folderName,
                    imageGroups[groupIndex].subAlbumName,
                    updatedTags,
                    imageUrls,
                  );
                  Navigator.of(context).pop();
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar subálbum: $error')),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
                              widget.folderName,
                              style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: imageGroups.length,
                        itemBuilder: (context, index) {
                          final group = imageGroups[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImagemDetalhesPage(
                                    images: group.images.map((img) => img.imageData).toList(),
                                    tags: group.tags,
                                    subAlbumName: group.subAlbumName,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.grey[900],
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    group.images.isNotEmpty
                                        ? Image.memory(
                                            group.images.first.imageData,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.photo_album,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'subalbum: ${group.subAlbumName}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            group.creationDate != null
                                                ? group.creationDate!.toLocal().toString().split(' ')[0]
                                                : 'Sem data',
                                            style: const TextStyle(
                                              color: Color.fromARGB(108, 255, 255, 255),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (group.tags.isNotEmpty)
                                            Wrap(
                                              spacing: 4.0,
                                              runSpacing: 4.0,
                                              children: group.tags
                                                  .map((tag) => Chip(
                                                        label: Text(
                                                          tag,
                                                          style: const TextStyle(fontSize: 12),
                                                        ),
                                                        backgroundColor: Colors.grey[300],
                                                        padding:
                                                            const EdgeInsets.symmetric(horizontal: 8.0),
                                                      ))
                                                  .toList(),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 48,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color(0xFFaed513),
                                            ),
                                            onPressed: () => _editSubAlbum(index),
                                            tooltip: 'Editar subálbum',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Color(0xFFaed513),
                                            ),
                                            onPressed: () => _addMoreTags(context, group),
                                            tooltip: 'Adicionar mais tags',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 600),
            child: Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : () async {
                  await _addMultipleImages();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFaed513),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  size: 35,
                ),
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

  const ImageGroupWidget({super.key, required this.group, required this.onEdit});

  @override
  State<ImageGroupWidget> createState() => _ImageGroupWidgetState();
}

class _ImageGroupWidgetState extends State<ImageGroupWidget> {
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
              onPressed: () async {
                List<String> newTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                setState(() {
                  widget.group.tags.addAll(newTags.where((tag) => !widget.group.tags.contains(tag)));
                });
                try {
                  final albunsCriadosState = context.findAncestorStateOfType<_AlbunsCriados>();
                  if (albunsCriadosState != null) {
                    await albunsCriadosState._createSubAlbum(
                      albunsCriadosState.widget.folderName,
                      widget.group.subAlbumName,
                      widget.group.tags,
                      [],
                    );
                  }
                  Navigator.of(context).pop();
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar tags: $error')),
                  );
                }
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
    final screenWidth = MediaQuery.of(context).size.width;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / (screenWidth * 0.33)).floor().clamp(1, 4);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Card(
              color: const Color.fromARGB(255, 223, 223, 223),
              margin: EdgeInsets.all(screenWidth * 0.033).copyWith(top: screenWidth * 0.083),
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
                      padding: EdgeInsets.all(screenWidth * 0.033),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: screenWidth * 0.022),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.group.tags.isNotEmpty)
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: screenWidth * 0.011,
                                    runSpacing: screenWidth * 0.011,
                                    children: widget.group.tags
                                        .map((tag) => Chip(
                                              label: Text(
                                                tag,
                                                style: TextStyle(fontSize: 12 * MediaQuery.of(context).textScaleFactor),
                                              ),
                                              backgroundColor: Colors.grey[300],
                                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.022),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: const Color(0xFFaed513),
                                  size: screenWidth * 0.067,
                                ),
                                onPressed: () => _addMoreTags(context),
                                tooltip: 'Adicionar mais tags',
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.033),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFaed513),
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.044, vertical: screenWidth * 0.033),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.022),
                              ),
                            ),
                            onPressed: widget.onEdit,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Editar',
                                  style: TextStyle(
                                    fontSize: 15 * MediaQuery.of(context).textScaleFactor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.022),
                                Icon(Icons.edit, size: screenWidth * 0.056),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.all(screenWidth * 0.011),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: screenWidth * 0.011,
                          mainAxisSpacing: screenWidth * 0.011,
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
                      padding: EdgeInsets.all(screenWidth * 0.033),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: screenWidth * 0.022),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.group.tags.isNotEmpty)
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: screenWidth * 0.011,
                                    runSpacing: screenWidth * 0.011,
                                    children: widget.group.tags
                                        .map((tag) => Chip(
                                              label: Text(
                                                tag,
                                                style: TextStyle(fontSize: 12 * MediaQuery.of(context).textScaleFactor),
                                              ),
                                              backgroundColor: Colors.grey[300],
                                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.022),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: const Color(0xFFaed513),
                                  size: screenWidth * 0.067,
                                ),
                                onPressed: () => _addMoreTags(context),
                                tooltip: 'Adicionar mais tags',
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.033),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFaed513),
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.044, vertical: screenWidth * 0.033),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.022),
                              ),
                            ),
                            onPressed: widget.onEdit,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Editar',
                                  style: TextStyle(
                                    fontSize: 15 * MediaQuery.of(context).textScaleFactor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.022),
                                Icon(Icons.edit, size: screenWidth * 0.056),
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
              top: -(screenWidth * 0.042),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.033, vertical: screenWidth * 0.011),
                decoration: BoxDecoration(
                  color: const Color(0xFFaed513),
                  borderRadius: BorderRadius.circular(screenWidth * 0.022),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: screenWidth * 0.011,
                      offset: Offset(0, screenWidth * 0.0056),
                    ),
                  ],
                ),
                child: Text(
                  widget.group.subAlbumName,
                  style: TextStyle(
                    fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}