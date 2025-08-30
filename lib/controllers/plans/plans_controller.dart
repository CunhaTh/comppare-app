import 'package:application_progress/main.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../helpers/helpers.dart';
import '../../infra/api_endponts.dart';
import '../../infra/api_services.dart';
import '../../infra/user_helper.dart';
import '../../models/plan_model.dart';

part 'plans_state.dart';

class PlansController extends Cubit<PlansState> {
  PlansController({
    required this.apiService,
  }) : super(PlansState.initial());

  final ApiService apiService;

  void setNickname(String nickname) {
    if (nickname.isEmpty) {
      emit(
        state.copyWith(
          status: AppStateStatus.failure,
          error: 'Nickname is required',
        ),
      );
      return;
    }
  }

  Future<void> subscribePlanByPix(PlanModel plan) async {
    emit(state.copyWith(status: AppStateStatus.loading));

    try {
      final userId = UserHelper().user?.id;
      if (userId != null) {
        final urlPix = Uri.parse('${ApiEndpoints.baseUrl}/pix/enviar');
        apiService.getFolderById(plan.id);
      } else {
        _showErrorDialog('Usuário não autenticado.');
      }
      emit(state.copyWith(status: AppStateStatus.success));
    } catch (e) {
      emit(state.copyWith(status: AppStateStatus.failure, error: e.toString()));
    }
  }

  Future<void> getPlanById(int planId) async {
    emit(state.copyWith(status: AppStateStatus.loading));

    try {
      final response = await apiService.getPlanById(planId);
      emit(state.copyWith(plan: response));

      emit(state.copyWith(status: AppStateStatus.success));
    } catch (e) {
      emit(state.copyWith(status: AppStateStatus.failure, error: e.toString()));
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
