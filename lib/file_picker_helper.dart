// lib/file_picker_helper.dart

import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart' as devtools;
import 'package:image_picker/image_picker.dart'; // Para XFile
import 'package:file_picker/file_picker.dart'; // Para PlatformFile
// Para devtools.debugPrint

// Importa PickedFileItem do seu modelo
import 'package:application_progress/models/image_model.dart';

// Importações condicionais para web e mobile


class FilePickerHelper {
  // Método para selecionar imagens e retornar uma lista de PickedFileItem
  static Future<List<PickedFileItem>> pickImages({required bool allowMultiple}) async {
    List<PickedFileItem> pickedFiles = [];
    devtools.debugPrint('FilePickerHelper.pickImages iniciado.');

    if (kIsWeb) {
      // Web: Usar file_picker (que lida com dart:html internamente)
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: allowMultiple,
          withData: true, // Garante que os bytes estejam disponíveis
        );

        if (result == null || result.files.isEmpty) {
          devtools.debugPrint('Nenhum arquivo selecionado na web.');
          return [];
        }

        for (var file in result.files) {
          if (file.bytes != null) {
            pickedFiles.add(PickedFileItem(platformFile: file));
          } else {
            devtools.debugPrint('Aviso: Arquivo ${file.name} não possui bytes disponíveis.');
          }
        }
      } catch (e) {
        devtools.debugPrint('Erro ao selecionar imagens na web: $e');
        throw Exception('Erro ao selecionar imagens na web: $e');
      }
    } else {
      // Mobile: Usar image_picker (ou file_picker se preferir)
      try {
        final ImagePicker picker = ImagePicker();
        final List<XFile> images = await picker.pickMultiImage(); // Ou picker.pickImage() para uma única

        if (images.isEmpty) {
          devtools.debugPrint('Nenhum arquivo selecionado no mobile.');
          return [];
        }

        for (var xFile in images) {
          final bytes = await xFile.readAsBytes();
          // Converte XFile para PlatformFile para consistência com PickedFileItem
          final platformFile = PlatformFile(
            name: xFile.name,
            size: bytes.length,
            bytes: bytes,
            path: xFile.path,
          );
          pickedFiles.add(PickedFileItem(platformFile: platformFile));
        }
      } catch (e) {
        devtools.debugPrint('Erro ao selecionar imagens no mobile: $e');
        throw Exception('Erro ao selecionar imagens no mobile: $e');
      }
    }

    devtools.debugPrint('pickImages retornou ${pickedFiles.length} PickedFileItems');
    return pickedFiles;
  }
}
