import 'dart:async';
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
import '../../principal.dart';
import '../../services/efipay_service.dart';
part 'payment_state.dart';

class PaymentController extends Cubit<PaymentState> {
  PaymentController({
    required this.apiService,
    required this.efipayService,
  }) : super(PaymentState.initial());

  final ApiService apiService;

  final EfipayService efipayService;

  final userId = UserHelper().user?.id ?? 0;

  void setPlan(PlanModel plan) {
    emit(state.copyWith(plan: plan));
  }

  void setPaymentType(EnumPaymentType paymentType) {
    emit(state.copyWith(paymentType: paymentType));
  }

  Future<PaymentReturnModel> switchPaymentType({
    required String number,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
    required String holderName,
    required String holderDocument,
  }) async {
    if (state.paymentType == EnumPaymentType.creditCard) {
      return await _generateCardToken(
        number: number,
        cvv: cvv,
        expirationMonth: expirationMonth,
        expirationYear: expirationYear,
        holderName: holderName,
        holderDocument: holderDocument,
      );
    } else if (state.paymentType == EnumPaymentType.pix) {
      return await _createPaymentWithPix(state.token ?? '');
    }
    return PaymentReturnModel.empty();
  }

  Future<PaymentReturnModel> _generateCardToken({
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
      return await createPaymentWithCard(token);
    } catch (e) {
      log('Erro ao gerar token: $e');
      // Em caso de erro, trate e propague a exceção
      return PaymentReturnModel.empty();
    }
  }

  Future<PaymentReturnModel> createPaymentWithCard(String token) async {
    try {
      if (userId == 0) {
        _showErrorDialog('Usuário não autenticado.');
        return PaymentReturnModel.empty();
      }

      final payment = PaymentModel(
        usuario: userId,
        plano: state.plan.id,
        valor: state.plan.valor,
        token: token,
      );

      final response = await apiService.createPaymentWithCard(payment);
      log('Pagamento via cartão de crédito criado: $response');
      return PaymentReturnModel(success: true, data: "");
    } catch (e) {
      log('Erro ao criar pagamento: $e');
      _showErrorDialog('Erro ao criar pagamento via cartão de crédito: $e');
      return PaymentReturnModel.empty();
    }
  }

  Future<PaymentReturnModel> _createPaymentWithPix(String token) async {
    try {
      final userId = UserHelper().user?.id;

      if (userId == null) {
        _showErrorDialog('Usuário não autenticado.');
        return PaymentReturnModel.empty();
      }

      final response = await apiService.createPaymentWithPix(
        userId: userId,
        planId: state.plan.id,
      );
      log('QrCode via pix criado: $response');
      //  emit(state.copyWith(qrCode: response['qrCode']));
      return PaymentReturnModel(success: true, data: response.pix);
    } catch (e) {
      log('Erro ao criar pagamento: $e');
      _showErrorDialog('Erro ao criar pagamento via pix: $e');
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
