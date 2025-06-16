import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:application_progress/principal.dart'; // Para ImageItem
import 'dart:html' as dart_html;
import 'dart:io' as dart_io;

// Armazena as imagens selecionadas temporariamente
class _SelectedImages {
  static List<dynamic>? _files; // Para web (List<dart_html.File>) ou mobile (List<XFile>)
  
  static void setFiles(List<dynamic> files) {
    _files = files;
  }
  
  static List<dynamic>? getFiles() {
    return _files;
  }
  
  static void clearFiles() {
    _files = null;
  }
}

class FilePickerHelper {
  // Método para selecionar imagens e retornar uma lista de ImageItem
  static Future<List<ImageItem>> pickImages(String subAlbumName) async {
    List<ImageItem> newImages = [];
    print('FilePickerHelper.pickImages iniciado para subAlbum: $subAlbumName');

    if (kIsWeb) {
      // Web: Usar dart:html
      try {
        final uploadInput = dart_html.FileUploadInputElement()..multiple = true;
        uploadInput.accept = 'image/*';
        uploadInput.click();

        await uploadInput.onChange.first;
        final files = uploadInput.files;
        if (files == null || files.isEmpty) {
          print('Nenhum arquivo selecionado na web');
          throw Exception('Nenhum arquivo selecionado.');
        }

        // Armazena os arquivos selecionados
        _SelectedImages.setFiles(files);

        for (var file in files) {
          final reader = dart_html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;
          final data = reader.result as Uint8List?;
          if (data == null) {
            throw Exception('Falha ao ler o arquivo: resultado nulo.');
          }
          newImages.add(ImageItem(
            imageData: data,
            subAlbumName: subAlbumName,
          ));
        }
      } catch (e) {
        print('Erro ao selecionar imagens na web: $e');
        throw Exception('Erro ao selecionar imagens na web: $e');
      }
    } else {
      // Mobile: Usar image_picker
      try {
        final ImagePicker picker = ImagePicker();
        final List<XFile>? images = await picker.pickMultiImage();
        if (images == null || images.isEmpty) {
          print('Nenhum arquivo selecionado no mobile');
          throw Exception('Nenhum arquivo selecionado.');
        }

        // Armazena os arquivos selecionados
        _SelectedImages.setFiles(images);

        for (var image in images) {
          final bytes = await dart_io.File(image.path).readAsBytes();
          newImages.add(ImageItem(
            imageData: bytes,
            subAlbumName: subAlbumName,
          ));
        }
      } catch (e) {
        print('Erro ao selecionar imagens no mobile: $e');
        throw Exception('Erro ao selecionar imagens no mobile: $e');
      }
    }

    print('pickImages retornou ${newImages.length} imagens');
    return newImages;
  }

  // Método para obter a lista de imagens a serem enviadas
  static Future<List<dynamic>> getImagesToUpload() async {
    List<dynamic> imagesToUpload = [];
    final files = _SelectedImages.getFiles();

    if (files == null || files.isEmpty) {
      print('Nenhum arquivo armazenado para upload');
      throw Exception('Nenhum arquivo disponível para upload.');
    }

    print('getImagesToUpload iniciado com ${files.length} arquivos');

    if (kIsWeb) {
      // Web: Reutiliza arquivos armazenados
      try {
        for (var file in files as List<dart_html.File>) {
          final reader = dart_html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;
          final data = reader.result as Uint8List?;
          if (data == null) {
            throw Exception('Falha ao ler o arquivo: resultado nulo.');
          }
          imagesToUpload.add(data);
        }
      } catch (e) {
        print('Erro ao obter imagens para upload na web: $e');
        throw Exception('Erro ao obter imagens para upload na web: $e');
      }
    } else {
      // Mobile: Reutiliza arquivos armazenados
      try {
        for (var image in files as List<XFile>) {
          final bytes = await dart_io.File(image.path).readAsBytes();
          imagesToUpload.add(bytes); // Alterado para retornar bytes, para consistência
        }
      } catch (e) {
        print('Erro ao obter imagens para upload no mobile: $e');
        throw Exception('Erro ao obter imagens para upload no mobile: $e');
      }
    }

    // Limpa os arquivos armazenados após uso
    _SelectedImages.clearFiles();
    print('getImagesToUpload retornou ${imagesToUpload.length} itens');
    return imagesToUpload;
  }
}