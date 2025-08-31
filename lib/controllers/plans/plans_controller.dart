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
  }) : super(const PlansState.initial());

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

  //   Future<void> subscribePlan({required void Function() pop}) async {
  //     try {
  //       // await loadAthletesFromJson();

  //       // Loader().show();
  //       // final result = await athletesRepository.saveAthlete(state.athlete);
  //       // result.fold(
  //       //   (success) {
  //       //     log('success');
  //       //     // emit(
  //       //     //   state.copyWith(
  //       //     //     athlete: success,
  //       //     //   ),
  //       //     // );

  //       //     // AppSnackbar().success(
  //       //     //   state.athlete.id.isEmpty
  //       //     //       ? navigatorKey.currentContext!.tr.athlete.sucessCreatedAthlete
  //       //     //       : navigatorKey.currentContext!.tr.athlete.sucessUpdatedAthlete,
  //       //     // );
  //       //   },
  //       //   (failure) {
  //       //     // customMessageError(
  //       //     //   messageDefault: state.athlete.id.isEmpty
  //       //     //       ? navigatorKey.currentContext!.tr.erros.registerAthlete
  //       //     //       : navigatorKey.currentContext!.tr.erros.updateAthlete,
  //       //     //   failure: failure,
  //       //     // );
  //       //   },
  //       // );
  //     } catch (e) {
  //       // AppSnackbar().error(
  //       //   state.athlete.id.isEmpty
  //       //       ? navigatorKey.currentContext!.tr.erros.registerAthlete
  //       //       : navigatorKey.currentContext!.tr.erros.updateAthlete,
  //       // );
  //       //
  //     } finally {
  //       //    Loader().hide();
  //     }
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