part of 'image_data_controller.dart';

class ImageDataState extends Equatable {
  const ImageDataState({
    required this.error,
    required this.status,
  });

  const ImageDataState.initial()
      : this(
          status: AppStateStatus.initial,
          error: '',
        );

  final AppStateStatus status;
  final String error;

  ImageDataState copyWith({
    error,
    AppStateStatus? status,
  }) {
    return ImageDataState(
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
