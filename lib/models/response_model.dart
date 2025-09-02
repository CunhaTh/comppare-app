class ResponseModel {
  final int codRetorno;
  final String message;
  ResponseModel({
    required this.codRetorno,
    required this.message,
  });

  ResponseModel copyWith({
    int? codRetorno,
    String? message,
  }) {
    return ResponseModel(
      codRetorno: codRetorno ?? this.codRetorno,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'codRetorno': codRetorno});
    result.addAll({'message': message});

    return result;
  }

  factory ResponseModel.fromMap(Map<String, dynamic> map) {
    return ResponseModel(
      codRetorno: map['codRetorno']?.toInt() ?? 0,
      message: map['message'] ?? '',
    );
  }

  factory ResponseModel.empty() {
    return ResponseModel(
      codRetorno: 0,
      message: '',
    );
  }

  @override
  String toString() =>
      'ResponseModel(codRetorno: $codRetorno, message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ResponseModel &&
        other.codRetorno == codRetorno &&
        other.message == message;
  }

  @override
  int get hashCode => codRetorno.hashCode ^ message.hashCode;
}
