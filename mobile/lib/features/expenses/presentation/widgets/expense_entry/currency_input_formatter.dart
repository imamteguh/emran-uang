import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter;

  CurrencyInputFormatter(this.formatter);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Strip all non-digits to get raw number value
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    double value = double.parse(digitsOnly);
    if (formatter.decimalDigits != null && formatter.decimalDigits! > 0) {
      value /= 100.0;
    }

    // Format the number part (without the currency symbol prefix)
    final String symbol = formatter.currencySymbol;
    final String formatted = formatter.format(value);

    // Safely remove the currency symbol from the formatted text
    final String formattedNumber = formatted
        .replaceFirst(symbol.trim(), '')
        .replaceFirst(symbol, '')
        .trim();

    return newValue.copyWith(
      text: formattedNumber,
      selection: TextSelection.collapsed(offset: formattedNumber.length),
    );
  }
}
