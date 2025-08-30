part of 'plans_controller.dart';

class PlansState extends Equatable {
  const PlansState({
    required this.error,
    required this.status,
    required this.plan,
  });

  PlansState.initial()
      : this(
          status: AppStateStatus.initial,
          error: '',
          plan: PlanModel.empty(),
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
      error: error ?? this.error,
      status: status ?? this.status,
      plan: plan ?? this.plan,
    );
  }

  @override
  List<Object> get props => [
        error,
        status,
        plan,
      ];
}
