import 'dart:async';
import 'dart:developer';

import 'package:application_progress/main.dart';
import 'package:bloc/bloc.dart';
import 'package:efipay/efipay.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
//import 'dart:js' as dartJsFile;

import 'dart:js' as js;

import '../../helpers/helpers.dart';
import '../../infra/api_services.dart';
import '../../services/efipay_service.dart';
part 'payment_state.dart';

class PaymentController extends Cubit<PaymentState> {
  PaymentController({
    required this.apiService,
    required this.efipayService,
  }) : super(const PaymentState.initial());

  final ApiService apiService;

  final EfipayService efipayService;

  Future<void> generateCardToken({
    required String number,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
    required String holderName,
    required String holderDocument,
  }) async {
    try {
      final token = await efipayService.generateCardToken(
        number: number,
        cvv: cvv,
        expirationMonth: expirationMonth,
        expirationYear: expirationYear,
        holderName: holderName,
        holderDocument: holderDocument,
      );
      log('Token gerado e recebido no DART(generateCardToken): $token');
    } catch (e) {
      log('Erro ao gerar token: $e');
      // Em caso de erro, trate e propague a exceção
      rethrow;
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
