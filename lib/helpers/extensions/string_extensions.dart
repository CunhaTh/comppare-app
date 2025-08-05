extension AppExtensionForString on String {
  String get cardBrand {
    final cardNumber = replaceAll(RegExp(r'\s+|-'), '');

    if (RegExp(r'^4[0-9]{12}(?:[0-9]{3})?$').hasMatch(cardNumber)) {
      return 'visa';
    } else if (RegExp(r'^(5[1-5][0-9]{14})$').hasMatch(cardNumber)) {
      return 'mastercard';
    } else if (RegExp(r'^(3[47][0-9]{13})$').hasMatch(cardNumber)) {
      return 'amex';
    } else if (RegExp(r'^(3(?:0[0-5]|[68][0-9])[0-9]{11})$')
        .hasMatch(cardNumber)) {
      return 'diners';
    } else if (RegExp(r'^(6(?:011|5[0-9]{2})[0-9]{12})$')
        .hasMatch(cardNumber)) {
      return 'discover';
    } else if (RegExp(r'^(35\d{14})$').hasMatch(cardNumber)) {
      return 'jcb';
    } else if (RegExp(
            r'^(4011|4312|4389|4514|4576|5041|5067|5090|6277|6362|6363|6504|6505|6507|6509|6516|6550)')
        .hasMatch(cardNumber)) {
      return 'elo';
    } else if (RegExp(r'^(606282|3841)').hasMatch(cardNumber)) {
      return 'hipercard';
    } else {
      return 'desconhecida';
    }
  }

  String get toCpfFormat {
    // Remove tudo que não for dígito
    final digits = replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 11) {
      return this; // Retorna original se não tiver 11 dígitos
    }

    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9, 11)}';
  }
}
