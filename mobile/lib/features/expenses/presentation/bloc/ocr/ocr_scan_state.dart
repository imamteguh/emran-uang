import 'dart:io';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/wallet.dart';

enum OcrScanStatus {
  initial,
  picking,
  scanning,
  success,
  failure,
}

class OcrScanState {
  final OcrScanStatus status;
  final File? selectedImage;
  final double? amount;
  final String? description;
  final DateTime? date;
  final ExpenseCategory? category;
  final String? rawSuggestion;
  final WalletEntity? activeWallet;
  final String? errorMessage;

  const OcrScanState({
    this.status = OcrScanStatus.initial,
    this.selectedImage,
    this.amount,
    this.description,
    this.date,
    this.category,
    this.rawSuggestion,
    this.activeWallet,
    this.errorMessage,
  });

  bool get isProcessing => status == OcrScanStatus.scanning;
  bool get hasResult => status == OcrScanStatus.success;

  OcrScanState copyWith({
    OcrScanStatus? status,
    File? selectedImage,
    double? amount,
    String? description,
    DateTime? date,
    ExpenseCategory? category,
    String? rawSuggestion,
    WalletEntity? activeWallet,
    String? errorMessage,
    bool clearImage = false,
    bool clearError = false,
  }) {
    return OcrScanState(
      status: status ?? this.status,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      rawSuggestion: rawSuggestion ?? this.rawSuggestion,
      activeWallet: activeWallet ?? this.activeWallet,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
