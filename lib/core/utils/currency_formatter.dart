import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _nairaFormatter = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
    customPattern: '¤#,##0.00',
  );

  static final _nairaCompactFormatter = NumberFormat.compactCurrency(
    symbol: '₦',
    decimalDigits: 1,
  );

  /// Format amount with Naira symbol and 2 decimal places (e.g., ₦500,000.00)
  static String formatNaira(double amount) {
    return _nairaFormatter.format(amount);
  }

  /// Compact Naira representation for large numbers (e.g. ₦1.5M)
  static String formatNairaCompact(double amount) {
    return _nairaCompactFormatter.format(amount);
  }

  /// Format crypto amounts up to 4 decimal places (e.g., 250.0000 USDT)
  static String formatCrypto(double amount, {String symbol = 'USDT'}) {
    final formatter = NumberFormat('#,##0.0000');
    return '${formatter.format(amount)} $symbol';
  }
}
