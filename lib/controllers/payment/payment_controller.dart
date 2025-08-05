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
  }) : super(const PaymentState.initial());

  final ApiService apiService;

  void generateCardToken() {
    final card = js.JsObject.jsify({
      'number': '4192801899905047',
      'cvv': '123',
      'expirationMonth': '08',
      'expirationYear': '2026',
      'holderName': 'Gorbadoc Oldbuck',
      'holderDocument': '94271564656',
      'reuse': false,
    });

    js.context.callMethod('generateToken', [card]);
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
