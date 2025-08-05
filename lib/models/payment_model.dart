class PaymentModel {
  final int usuario;
  final int plano;
  final double valor;
  final String token;
  PaymentModel({
    required this.usuario,
    required this.plano,
    required this.valor,
    required this.token,
  });

  PaymentModel copyWith({
    int? usuario,
    int? plano,
    double? valor,
    String? token,
  }) {
    return PaymentModel(
      usuario: usuario ?? this.usuario,
      plano: plano ?? this.plano,
      valor: valor ?? this.valor,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'usuario': usuario});
    result.addAll({'plano': plano});
    result.addAll({'valor': valor});
    result.addAll({'token': token});

    return result;
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      usuario: map['usuario']?.toInt() ?? 0,
      plano: map['plano']?.toInt() ?? 0,
      valor: map['valor']?.toDouble() ?? 0.0,
      token: map['token'] ?? '',
    );
  }

  factory PaymentModel.empty() {
    return PaymentModel(
      usuario: 0,
      plano: 0,
      valor: 0.0,
      token: '',
    );
  }

  @override
  String toString() {
    return 'PaymentModel(usuario: $usuario, plano: $plano, valor: $valor, token: $token)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentModel &&
        other.usuario == usuario &&
        other.plano == plano &&
        other.valor == valor &&
        other.token == token;
  }

  @override
  int get hashCode {
    return usuario.hashCode ^ plano.hashCode ^ valor.hashCode ^ token.hashCode;
  }
}
