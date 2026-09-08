import '../../../domain/entities/expense.dart';
import '../../../domain/entities/wallet.dart';

enum ExpenseEntryStatus {
  initial,
  submitting,
  success,
  failure,
}

class ExpenseEntryState {
  final ExpenseEntryStatus status;
  final ExpenseCategory? selectedCategory;
  final DateTime selectedDate;
  final bool isRoutine;
  final WalletEntity? activeWallet;
  final String? errorMessage;
  final String? formattedAmount;
  final String? initialDescription;

  ExpenseEntryState({
    this.status = ExpenseEntryStatus.initial,
    this.selectedCategory,
    DateTime? selectedDate,
    this.isRoutine = false,
    this.activeWallet,
    this.errorMessage,
    this.formattedAmount,
    this.initialDescription,
  }) : selectedDate = selectedDate ?? DateTime.now();

  bool get isSubmitting => status == ExpenseEntryStatus.submitting;
  bool get isSuccess => status == ExpenseEntryStatus.success;

  ExpenseEntryState copyWith({
    ExpenseEntryStatus? status,
    ExpenseCategory? selectedCategory,
    DateTime? selectedDate,
    bool? isRoutine,
    WalletEntity? activeWallet,
    String? errorMessage,
    String? formattedAmount,
    String? initialDescription,
    bool clearError = false,
  }) {
    return ExpenseEntryState(
      status: status ?? this.status,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedDate: selectedDate ?? this.selectedDate,
      isRoutine: isRoutine ?? this.isRoutine,
      activeWallet: activeWallet ?? this.activeWallet,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      formattedAmount: formattedAmount ?? this.formattedAmount,
      initialDescription: initialDescription ?? this.initialDescription,
    );
  }
}
