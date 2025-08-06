class PaymentReturnModel {
  final bool success;
  final String data;
  PaymentReturnModel({
    required this.success,
    required this.data,
  });

  PaymentReturnModel copyWith({
    bool? success,
    String? data,
  }) {
    return PaymentReturnModel(
      success: success ?? this.success,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'success': success});
    result.addAll({'data': data});

    return result;
  }

  factory PaymentReturnModel.fromMap(Map<String, dynamic> map) {
    return PaymentReturnModel(
      success: map['success'] ?? false,
      data: map['data'] ?? '',
    );
  }

  factory PaymentReturnModel.empty() {
    return PaymentReturnModel(
      success: false,
      data: '',
    );
  }

  @override
  String toString() {
    return 'PaymentReturnModel(success: $success, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentReturnModel &&
        other.success == success &&
        other.data == data;
  }

  @override
  int get hashCode {
    return success.hashCode ^ data.hashCode;
  }
}
