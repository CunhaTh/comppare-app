import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/comppareimg.dart' hide ImageItem;
import 'package:collection/collection.dart';
import 'file_picker_helper.dart'; // Nova importação
// Alias para evitar conflitos
import 'dart:io' as dart_io show File;
import 'dart:html' as dart_html;

class AlbunsCriados extends StatefulWidget {
  final String folderName;
  final int? folderId;
  final List<ImageGroup> subfolders;

  const AlbunsCriados({
    super.key,
    required this.folderName,
    this.folderId,
    this.subfolders = const [],
  });

  @override
  State<AlbunsCriados> createState() => _AlbunsCriados();
}

class SubAlbumData {
  final String name;
  final List<String> tags;

  SubAlbumData({required this.name, required this.tags});
}

class _AlbunsCriados extends State<AlbunsCriados> {
  late List<ImageGroup> imageGroups;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa com uma lista vazia para evitar acesso prematuro
    imageGroups = widget.subfolders;
  }

@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Carrega os argumentos apenas após o contexto estar pronto
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final subfoldersJson = arguments?['subfolders'] as List<dynamic>? ?? [];
    setState(() {
      imageGroups = subfoldersJson
          .map((json) => ImageGroup.fromJson(json as Map<String, dynamic>))
          .toList();
      if (imageGroups.isEmpty) {
        imageGroups = widget.subfolders;
      }
    });
    _checkAuthentication();
  }

void _checkAuthentication() {
    final String? authToken = UserHelper.instance.user?.token;
    if (authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token de autenticação não encontrado. Faça login novamente.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      debugPrint('Token presente na tela AlbunsCriados: $authToken');
    }
  }

  Future<void> _addMultipleImages() async {
  // Evita chamadas duplicadas enquanto a função está em execução
  if (isLoading) return;

  SubAlbumData? subAlbumData = await _promptSubAlbumName();
  if (subAlbumData == null || subAlbumData.name.isEmpty) return;

  List<ImageItem> newImages = [];
  List<dynamic> imagesToUpload = [];

  final scaffoldMessenger = ScaffoldMessenger.of(context);

  setState(() {
    isLoading = true;
  });

  try {
    // Usa a nova classe FilePickerHelper para selecionar imagens
    newImages = await FilePickerHelper.pickImages(subAlbumData.name);
    if (newImages.isEmpty) {
      // Caso nenhuma imagem seja selecionada, interrompe o fluxo
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Nenhuma imagem selecionada.')),
      );
      return;
    }

    // Obtém as imagens para upload (se necessário)
    imagesToUpload = await FilePickerHelper.getImagesToUpload();

    // Adiciona o novo grupo de imagens ao estado
    setState(() {
      imageGroups.add(ImageGroup(
        subAlbumName: subAlbumData.name,
        images: newImages,
        tags: subAlbumData.tags,
        creationDate: DateTime.now(),
      ));
    });

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Subálbum criado localmente com sucesso.')),
    );
  } catch (error) {
    if (!mounted) return;
    debugPrint('Erro ao adicionar imagens: $error');
    final errorMessage = error.toString().replaceFirst('Exception: ', '');
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Erro ao adicionar imagens: $errorMessage. Subálbum criado localmente.'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  Future<void> _showSaveDialog(Uint8List imageData) async {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Salvar Imagem', style: TextStyle(fontSize: 20.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome do Subálbum',
                  labelStyle: TextStyle(fontSize: 16.sp),
                ),
              ),
              SizedBox(height: 10.h),
              Text('Deseja salvar a imagem com esse nome?', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(fontSize: 16.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    final existingGroup = imageGroups.firstWhere(
                      (group) => group.subAlbumName == name,
                      orElse: () => ImageGroup(
                        subAlbumName: name,
                        images: [],
                        creationDate: DateTime.now(),
                      ),
                    );
                    existingGroup.images.add(ImageItem(imageData: imageData, subAlbumName: name));
                    if (!imageGroups.contains(existingGroup)) {
                      imageGroups.add(existingGroup);
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subálbum criado localmente.')),
                  );

                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome do subálbum não pode estar vazio.')),
                  );
                }
              },
              child: Text('Salvar', style: TextStyle(fontSize: 16.sp)),
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
          title: Text('Adicionar Tags', style: TextStyle(fontSize: 20.sp)),
          content: TextField(
            controller: tagsController,
            decoration: InputDecoration(
              labelText: 'Digite novas tags (separadas por vírgula)',
              labelStyle: TextStyle(fontSize: 16.sp),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(fontSize: 16.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> newTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                setState(() {
                  group.tags.addAll(newTags.where((tag) => !group.tags.contains(tag)));
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tags adicionadas localmente.')),
                );
              },
              child: Text('Adicionar', style: TextStyle(fontSize: 16.sp)),
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
          title: Text('Nome do Subálbum', style: TextStyle(fontSize: 20.sp)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Digite o nome do subálbum',
                  labelStyle: TextStyle(fontSize: 16.sp),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: tagsController,
                decoration: InputDecoration(
                  labelText: 'Digite as tags (separadas por vírgula)',
                  labelStyle: TextStyle(fontSize: 16.sp),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancelar', style: TextStyle(fontSize: 16.sp)),
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
              child: Text('OK', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editSubAlbum(int groupIndex) async {
    if (imageGroups.isEmpty || groupIndex < 0 || groupIndex >= imageGroups.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subálbum inválido ou não encontrado.')),
      );
      return;
    }

    final String subAlbumName = imageGroups[groupIndex].subAlbumName;
    TextEditingController tagsController = TextEditingController(
      text: imageGroups[groupIndex].tags.join(', '),
    );
    List<ImageItem> newImages = [];
    List<dynamic> imagesToUpload = [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Subálbum', style: TextStyle(fontSize: 20.sp)),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Usa a nova classe FilePickerHelper
                          final pickedImages = await FilePickerHelper.pickImages(subAlbumName);
                          final uploadedImages = await FilePickerHelper.getImagesToUpload();
                          setState(() {
                            newImages.addAll(pickedImages);
                            imagesToUpload.addAll(uploadedImages);
                          });
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao adicionar fotos: $error')),
                          );
                        }
                      },
                      child: Text(
                        kIsWeb ? 'Adicionar Fotos (Web)' : 'Adicionar Fotos (Mobile)',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (newImages.isNotEmpty) ...[
                      Text(
                        'Novas Imagens:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        constraints: BoxConstraints(maxHeight: 150.h),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: newImages.map((image) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      image.imageData,
                                      width: 100.w,
                                      height: 100.h,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            final indexToRemove = imagesToUpload.indexWhere((img) {
                                              if (img is Uint8List && image.imageData is Uint8List) {
                                                return listEquals(
                                                    (img as Uint8List).toList(), image.imageData.toList());
                                              }
                                              return false;
                                            });
                                            if (indexToRemove != -1) {
                                              imagesToUpload.removeAt(indexToRemove);
                                            }
                                            newImages.remove(image);
                                          });
                                        },
                                        child: CircleAvatar(
                                          radius: 12.r,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close, color: Colors.white, size: 16.sp),
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
                      SizedBox(height: 16.h),
                    ],
                    TextField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        labelText: 'Editar tags (separadas por vírgula)',
                        labelStyle: TextStyle(fontSize: 16.sp),
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
                imagesToUpload.clear();
              },
              child: Text('Cancelar', style: TextStyle(fontSize: 16.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> updatedTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                setState(() {
                  if (imageGroups.isEmpty || groupIndex < 0 || groupIndex >= imageGroups.length) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Índice de subálbum inválido ao salvar.')),
                    );
                    return;
                  }
                  imageGroups[groupIndex].images.addAll(newImages);
                  imageGroups[groupIndex].tags = updatedTags;
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subálbum atualizado localmente.')),
                );
              },
              child: Text('Salvar', style: TextStyle(fontSize: 16.sp)),
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
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                "assets/logo_cortada.png",
                width: 100,
                height: 30,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.logout, size: 24.sp),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 15.w, top: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Album:  ', style: TextStyle(color: Colors.black, fontSize: 15.sp)),
                        Container(
                          height: 30.h,
                          width: 120.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            color: const Color(0xFFaed513),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(left: 30.w, top: 5.h),
                            child: Text(
                              widget.folderName,
                              style: TextStyle(fontSize: 15.sp, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50.h),
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
                              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    group.images.isNotEmpty
                                        ? Image.memory(
                                            group.images.first.imageData,
                                            width: 40.w,
                                            height: 40.h,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.photo_album,
                                            size: 40.sp,
                                            color: Colors.white,
                                          ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'subalbum: ${group.subAlbumName}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            group.creationDate != null
                                                ? group.creationDate!.toLocal().toString().split(' ')[0]
                                                : 'Sem data',
                                            style: TextStyle(
                                              color: const Color.fromARGB(108, 255, 255, 255),
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          if (group.tags.isNotEmpty)
                                            Wrap(
                                              spacing: 4.w,
                                              runSpacing: 4.h,
                                              children: group.tags
                                                  .map((tag) => Chip(
                                                        label: Text(
                                                          tag,
                                                          style: TextStyle(fontSize: 12.sp),
                                                        ),
                                                        backgroundColor: Colors.grey[300],
                                                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                                                      ))
                                                  .toList(),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 48.w,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: const Color(0xFFaed513),
                                              size: 24.sp,
                                            ),
                                            onPressed: () => _editSubAlbum(index),
                                            tooltip: 'Editar subálbum',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add_circle,
                                              color: const Color(0xFFaed513),
                                              size: 24.sp,
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
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 28.w,
            bottom: 16.h,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFaed513),
              onPressed: isLoading ? null : _addMultipleImages,
              child: Icon(Icons.add_a_photo, size: 35.sp),
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
          title: Text('Adicionar Tags', style: TextStyle(fontSize: 20.sp)),
          content: TextField(
            controller: tagsController,
            decoration: InputDecoration(
              labelText: 'Digite novas tags (separadas por vírgula)',
              labelStyle: TextStyle(fontSize: 16.sp),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(fontSize: 16.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> newTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                setState(() {
                  widget.group.tags.addAll(newTags.where((tag) => !widget.group.tags.contains(tag)));
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tags adicionadas localmente.')),
                );
              },
              child: Text('Adicionar', style: TextStyle(fontSize: 16.sp)),
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
                                                style: TextStyle(fontSize: 12.sp),
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
                          Center(
                            child: ElevatedButton(
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
                                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: screenWidth * 0.022),
                                  Icon(Icons.edit, size: screenWidth * 0.056),
                                ],
                              ),
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
                                                style: TextStyle(fontSize: 12.sp),
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
                                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
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
                    fontSize: 16.sp,
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