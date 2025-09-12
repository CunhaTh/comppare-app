import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:application_progress/main.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
//import 'dart:js' as dartJsFile;

import '../../helpers/helpers.dart';
import '../../infra/api_services.dart';
import '../../infra/user_helper.dart';
import '../../models/models.dart';

part 'image_data_state.dart';

class ImageDataController extends Cubit<ImageDataState> {
  ImageDataController({
    required this.apiService,
  }) : super(const ImageDataState.initial());

  final ApiService apiService;

  final userId = UserHelper().user?.id ?? 0;

  Future<PaymentReturnModel> saveImageData({
    required int idPhoto,
    required String dataComparacao,
  }) async {
    try {
      if (userId == 0) {
        _showErrorDialog('Usuário não autenticado.');
        return PaymentReturnModel.empty();
      }

      final response = await apiService.saveImageData({
        "id_usuario": userId,
        "id_photo": idPhoto,
        "data_comparacao": dataComparacao
      });

      log("RESPOSTA DA API - SALVAR DADOS DA IMAGEM: ${jsonEncode(response)}");

      return PaymentReturnModel(success: true, data: "");
    } catch (e) {
      log('Erro ao salvar dados da imagem: $e');
      // _showErrorDialog('Erro ao salvar dados da imagem: $e');
      return PaymentReturnModel.empty();
    }
  }
}

void _showErrorDialog(String message) {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) => AlertDialog(
      title: const Text('Erro'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}
