import 'package:intl/intl.dart';

class CurrencyHelper {
  /// Returns the NumberFormat for a given ISO 4217 currency code.
  static NumberFormat getFormatter(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$ ',
          decimalDigits: 2,
        );
      case 'EUR':
        return NumberFormat.currency(
          locale: 'de_DE',
          symbol: '€ ',
          decimalDigits: 2,
        );
      case 'SGD':
        return NumberFormat.currency(
          locale: 'en_SG',
          symbol: 'S\$ ',
          decimalDigits: 2,
        );
      case 'JPY':
        return NumberFormat.currency(
          locale: 'ja_JP',
          symbol: '¥ ',
          decimalDigits: 0,
        );
      case 'IDR':
      default:
        return NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
    }
  }

  /// Formats the double value to the given currency code's style.
  static String format(double amount, String currencyCode) {
    return getFormatter(currencyCode).format(amount);
  }
}
