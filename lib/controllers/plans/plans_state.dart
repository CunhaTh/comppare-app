part of 'plans_controller.dart';

class PlansState extends Equatable   {
  const PlansState({

    required this.error,
    required this.status,
  
  });

  const PlansState.initial()
      : this(
      
          status: AppStateStatus.initial,
          error: '',
        
        );


  final AppStateStatus status;
  final String error;


  PlansState copyWith({

    String? error,
    AppStateStatus? status,

  }) {
    return PlansState(
      error: error ?? this.error,
      status: status ?? this.status,
     
    );
  }

  @override
  List<Object> get props => [
        error,
        status,
       
      ];
}
