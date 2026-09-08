import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/ocr_service.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/ocr_scan_result.dart';
import '../../../domain/entities/wallet.dart';
import 'ocr_scan_state.dart';

class OcrScanCubit extends Cubit<OcrScanState> {
  final OcrService _ocrService;

  OcrScanCubit({
    OcrService? ocrService,
    WalletEntity? initialWallet,
  })  : _ocrService = ocrService ?? OcrService(),
        super(OcrScanState(activeWallet: initialWallet));

  /// Initialize target wallet if not already set.
  void initWallet(WalletEntity? wallet) {
    if (state.activeWallet == null && wallet != null) {
      debugPrint('[OCR Cubit] 💼 Initialized wallet: ${wallet.name} (${wallet.currency})');
      emit(state.copyWith(activeWallet: wallet));
    }
  }

  /// Switch the target wallet for receipt scanning.
  void switchWallet(WalletEntity wallet) {
    debugPrint('[OCR Cubit] 🔄 Switched wallet: ${wallet.name} (${wallet.currency})');
    emit(state.copyWith(activeWallet: wallet));
  }

  /// Update the categorized item.
  void updateCategory(ExpenseCategory category) {
    emit(state.copyWith(category: category));
  }

  /// Update transaction amount.
  void updateAmount(double amount) {
    emit(state.copyWith(amount: amount));
  }

  /// Update description.
  void updateDescription(String? description) {
    emit(state.copyWith(description: description));
  }

  /// Update date.
  void updateDate(DateTime? date) {
    emit(state.copyWith(date: date));
  }

  /// Picks and crops an image, then immediately runs backend OCR.
  Future<void> pickAndProcessImage({
    required ImageSource source,
    required List<ExpenseCategory> availableCategories,
  }) async {
    try {
      debugPrint('[OCR Cubit] 📸 pickAndProcessImage started for source: $source');
      final croppedFile = await _ocrService.pickAndCropImage(source);
      if (croppedFile == null) {
        debugPrint('[OCR Cubit] 📸 No image picked or user cancelled');
        return;
      }

      debugPrint('[OCR Cubit] 🖼️ Image ready for OCR: ${croppedFile.path}');
      emit(state.copyWith(
        selectedImage: croppedFile,
        status: OcrScanStatus.scanning,
        clearError: true,
      ));

      await _processImage(
        image: croppedFile,
        availableCategories: availableCategories,
      );
    } catch (e) {
      debugPrint('[OCR Cubit] ❌ pickAndProcessImage error: $e');
      emit(state.copyWith(
        status: OcrScanStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Retries scanning with the already selected and cropped image.
  Future<void> retryCurrentProcess({
    required List<ExpenseCategory> availableCategories,
  }) async {
    final image = state.selectedImage;
    if (image == null) return;

    debugPrint('[OCR Cubit] 🔄 Retrying scan for image: ${image.path}');
    emit(state.copyWith(
      status: OcrScanStatus.scanning,
      clearError: true,
    ));

    await _processImage(
      image: image,
      availableCategories: availableCategories,
    );
  }

  Future<void> _processImage({
    required File image,
    required List<ExpenseCategory> availableCategories,
  }) async {
    try {
      debugPrint('[OCR Cubit] ⏳ Processing image via backend OCR: ${image.path}');
      final parsed = await _ocrService.scanReceiptImage(
        image: image,
        walletId: state.activeWallet?.id,
        availableCategories: availableCategories,
      );

      debugPrint('[OCR Cubit] ✅ Scan successful: amount=${parsed.amount}, category=${parsed.category?.name}, date=${parsed.date}');
      emit(state.copyWith(
        status: OcrScanStatus.success,
        amount: parsed.amount,
        description: parsed.description,
        date: parsed.date,
        category: parsed.category,
        rawSuggestion: parsed.rawSuggestion,
        clearError: true,
      ));
    } catch (e) {
      debugPrint('[OCR Cubit] ❌ OCR scan failed: $e');
      emit(state.copyWith(
        status: OcrScanStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Validates and constructs the final [OcrScanResult].
  OcrScanResult? createScanResult() {
    if (state.amount == null || state.amount! <= 0) {
      return null;
    }
    return OcrScanResult(
      amount: state.amount!,
      description: state.description,
      date: state.date,
      category: state.category,
      wallet: state.activeWallet,
    );
  }
}
