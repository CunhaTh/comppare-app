part of 'payment_controller.dart';

class PaymentState extends Equatable {
  const PaymentState({
    required this.error,
    required this.status,
    this.token,
  });

  const PaymentState.initial()
      : this(
          status: AppStateStatus.initial,
          error: '',
          token: '',
        );

  final AppStateStatus status;
  final String error;
  final String? token;
  PaymentState copyWith({
    String? error,
    AppStateStatus? status,
    String? token,
  }) {
    return PaymentState(
      error: error ?? this.error,
      status: status ?? this.status,
      token: token ?? this.token,
    );
  }

  @override
  List<Object> get props => [
        error,
        status,
        token ?? '',
      ];
}
