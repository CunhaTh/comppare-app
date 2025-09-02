part of 'plans_controller.dart';

class PlansState extends Equatable {
  const PlansState({
    required this.error,
    required this.status,
    required this.plan,
  });

  PlansState.initial()
      : this(
          plan: PlanModel.empty(),
          status: AppStateStatus.initial,
          error: '',
        );

  final AppStateStatus status;
  final String error;
  final PlanModel plan;

  PlansState copyWith({
    String? error,
    AppStateStatus? status,
    PlanModel? plan,
  }) {
    return PlansState(
      plan: plan ?? this.plan,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [
        error,
        status,
        plan,
      ];
}
