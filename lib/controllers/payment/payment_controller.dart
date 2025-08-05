import 'dart:developer';

import 'package:application_progress/main.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../helpers/helpers.dart';
import '../../infra/api_services.dart';
import '../../services/efipay_service.dart';
part 'payment_state.dart';

class PaymentController extends Cubit<PaymentState> {
  PaymentController({
    required this.apiService,
  }) : super(const PaymentState.initial());

  final ApiService apiService;

  Future<String> generateCardToken({
    // required String brand,
    required String number,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
  }) async {
    try {
      log(
        'DADOS DO CARTÃO:  number: $number, cvv: $cvv, expirationMonth: $expirationMonth, expirationYear: $expirationYear',
      );
      // final token = await EfipayService.generatePaymentToken(
      //   brand: number.cardBrand,
      //   number: number,
      //   cvv: cvv,
      //   expirationMonth: expirationMonth,
      //   expirationYear: expirationYear,
      // );

      // emit(state.copyWith(status: AppStateStatus.success, token: token));
      // return token ?? '';

      return '';
    } catch (e) {
      emit(state.copyWith(status: AppStateStatus.failure, error: e.toString()));
      _showErrorDialog(e.toString());
      rethrow;
    }
  }

  // void setNickname(String nickname) {
  //   if (nickname.isEmpty) {
  //     emit(
  //       state.copyWith(
  //         status: AppStateStatus.failure,
  //         error: 'Nickname is required',
  //       ),
  //     );
  //     return;
  //   }
  // }
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
