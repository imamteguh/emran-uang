import 'expense.dart';
import 'wallet.dart';

/// Result data from OCR scanning, passed back to ExpenseEntryScreen or Dashboard.
class OcrScanResult {
  final double amount;
  final String? description;
  final DateTime? date;
  final ExpenseCategory? category;
  final WalletEntity? wallet;

  const OcrScanResult({
    required this.amount,
    this.description,
    this.date,
    this.category,
    this.wallet,
  });
}
