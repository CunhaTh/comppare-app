part of 'payment_controller.dart';

class PaymentState extends Equatable {
  const PaymentState({
    required this.plan,
    required this.error,
    required this.status,
    this.token,
    required this.paymentType,
  });

  PaymentState.initial()
      : this(
          plan: PlanModel.empty(),
          status: AppStateStatus.initial,
          error: '',
          token: '',
          paymentType: EnumPaymentType.empty,
        );

  final PlanModel plan;
  final AppStateStatus status;
  final String error;
  final String? token;
  final EnumPaymentType paymentType;

  PaymentState copyWith({
    String? error,
    AppStateStatus? status,
    String? token,
    PlanModel? plan,
    EnumPaymentType? paymentType,
  }) {
    return PaymentState(
      error: error ?? this.error,
      status: status ?? this.status,
      token: token ?? this.token,
      plan: plan ?? this.plan,
      paymentType: paymentType ?? this.paymentType,
    );
  }

  @override
  List<Object> get props => [
        error,
        status,
        token ?? '',
        plan,
        paymentType,
      ];
}
