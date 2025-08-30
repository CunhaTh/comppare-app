import 'package:application_progress/main.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../helpers/helpers.dart';
import '../../infra/api_endponts.dart';
import '../../infra/api_exception.dart';
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
        final globalContext = navigatorKey.currentContext;
        if (globalContext != null) {
          ScaffoldMessenger.of(globalContext).showSnackBar(
            const SnackBar(
              content: Text('Usuário não autenticado.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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

  Future<void> cancelPlan({
    required int userId,
    required BuildContext context,
  }) async {
    emit(state.copyWith(status: AppStateStatus.loading));

    if (!_validateUser(userId, context)) return;

    _showLoadingDialog(context);

    try {
      final response = await apiService.cancelPlan(userId);

      // Fechar loading antes de mostrar outros diálogos
      _dismissLoadingDialog(context);

      if (response) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MyHomePage(title: ''),
          ),
        );
      } else {
        _handleFailure(context, 'Falha ao cancelar plano');
      }
    } on ApiException catch (e) {
      // Fechar loading antes de mostrar erro
      _dismissLoadingDialog(context);
      _handleError(context, e.message);
    }
  }

  bool _validateUser(int userId, BuildContext context) {
    if (userId == 0) {
      emit(state.copyWith(
        status: AppStateStatus.failure,
        error: 'Usuário não autenticado',
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não autenticado.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  void _showLoadingDialog(BuildContext context) {
    // Usar o contexto global para evitar problemas de contexto descartado
    final globalContext = navigatorKey.currentContext;
    if (globalContext != null) {
      showDialog(
        context: globalContext,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            content: Row(
              children: [
                CircularProgressIndicator(color: Color(0xFFaed513)),
                SizedBox(width: 20),
                Text(
                  'Cancelando assinatura...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _dismissLoadingDialog(BuildContext context) {
    // Usar o contexto global para fechar o diálogo
    final globalContext = navigatorKey.currentContext;
    if (globalContext != null) {
      try {
        Navigator.of(globalContext).pop();
      } catch (e) {
        // Se não conseguir fechar o diálogo, não faz nada
        // Isso pode acontecer se o diálogo já foi fechado
      }
    }
  }

  // Future<void> _handleSuccess(BuildContext context) async {
  //   emit(state.copyWith(status: AppStateStatus.success));

  //   if (!context.mounted) return;

  //   showSuccessSnackBar('Assinatura cancelada com sucesso!');

  //   // Aguardar antes de redirecionar
  //   await Future.delayed(const Duration(seconds: 2));

  //   if (context.mounted) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => const MyHomePage(title: ''),
  //       ),
  //     );
  //   }
  // }

  void showSuccessSnackBar(String message) {
    // Evita conflitos se já houver outro snackbar
    final messenger = ScaffoldMessenger.of(navigatorKey.currentContext!);
    // if (messenger == null) {
    //   // Caso seja chamado muito cedo no build, agenda para o próximo frame
    //   WidgetsBinding.instance
    //       .addPostFrameCallback((_) => showSuccessSnackBar(message));
    //   return;
    // }
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFAED513),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _handleFailure(BuildContext context, String message) {
    emit(state.copyWith(
      status: AppStateStatus.failure,
      error: message,
    ));

    // Aguardar um pouco antes de mostrar o erro para garantir que o loading foi fechado
    Future.delayed(const Duration(milliseconds: 300), () {
      _showSnackBarMessage(message);
    });
  }

  void _showSnackBarMessage(String message) {
    final globalContext = navigatorKey.currentContext;
    if (globalContext != null) {
      try {
        // Verificar se o ScaffoldMessenger está disponível
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(globalContext);
        if (scaffoldMessenger != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Fallback: tentar usar o contexto diretamente
          ScaffoldMessenger.of(globalContext).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        // Se houver erro, logar para debug
        print('Erro ao mostrar SnackBar: $e');
      }
    } else {
      print('Contexto global não disponível para mostrar SnackBar: $message');
    }
  }

  void _handleError(BuildContext context, String error) {
    emit(state.copyWith(
      status: AppStateStatus.failure,
      error: error,
    ));

    // Aguardar um pouco antes de mostrar o erro para garantir que o loading foi fechado
    Future.delayed(const Duration(milliseconds: 300), () {
      _showSnackBarMessage('Erro ao cancelar plano: $error');
    });
  }
}
