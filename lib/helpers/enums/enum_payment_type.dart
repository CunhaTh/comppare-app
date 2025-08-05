enum EnumPaymentType {
  creditCard,
  pix,
  empty,
}

extension EnumPaymentTypeExtension on EnumPaymentType {
  String get label => switch (this) {
        EnumPaymentType.creditCard => 'Cartão de Crédito',
        EnumPaymentType.pix => 'PIX',
        EnumPaymentType.empty => '',
      };
}
