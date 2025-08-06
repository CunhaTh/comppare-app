import 'dart:convert';

class PaymentPixReturnModel {
  final int codRetorno;
  final String message;
  final String pix;
  PaymentPixReturnModel({
    required this.codRetorno,
    required this.message,
    required this.pix,
  });

  PaymentPixReturnModel copyWith({
    int? codRetorno,
    String? message,
    String? pix,
  }) {
    return PaymentPixReturnModel(
      codRetorno: codRetorno ?? this.codRetorno,
      message: message ?? this.message,
      pix: pix ?? this.pix,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'codRetorno': codRetorno});
    result.addAll({'message': message});
    result.addAll({'pix': pix});

    return result;
  }

  factory PaymentPixReturnModel.fromMap(Map<String, dynamic> map) {
    return PaymentPixReturnModel(
      codRetorno: map['codRetorno']?.toInt() ?? 0,
      message: map['message'] ?? '',
      pix: map['data'] != null ? map['data']['pix'] : '',
    );
  }

  factory PaymentPixReturnModel.empty() {
    return PaymentPixReturnModel(
      codRetorno: 0,
      message: '',
      pix: "",
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentPixReturnModel.fromJson(String source) =>
      PaymentPixReturnModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'PaymentPixReturnModel(codRetorno: $codRetorno, message: $message, pix: $pix)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentPixReturnModel &&
        other.codRetorno == codRetorno &&
        other.message == message &&
        other.pix == pix;
  }

  @override
  int get hashCode => codRetorno.hashCode ^ message.hashCode ^ pix.hashCode;
}
