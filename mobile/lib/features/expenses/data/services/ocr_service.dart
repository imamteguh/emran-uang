import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/expense.dart';

/// Structured parsed data returned by the backend OCR service.
class OcrParsedData {
  final double amount;
  final String? description;
  final DateTime? date;
  final ExpenseCategory? category;
  final String? rawSuggestion;

  const OcrParsedData({
    required this.amount,
    this.description,
    this.date,
    this.category,
    this.rawSuggestion,
  });
}

/// Service handling image picking, cropping, and OCR backend requests.
class OcrService {
  final ImagePicker _picker;
  final DioClient _client;

  OcrService({
    ImagePicker? picker,
    DioClient? client,
  })  : _picker = picker ?? ImagePicker(),
        _client = client ?? DioClient();

  /// Picks an image from the given [source] and opens the cropper tool.
  Future<File?> pickAndCropImage(ImageSource source) async {
    try {
      debugPrint('[OCR Service] 📸 Picking image from source: $source');
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) {
        debugPrint('[OCR Service] 📸 Image picking cancelled by user');
        return null;
      }

      final fileLength = await picked.length();
      debugPrint('[OCR Service] 📸 Image picked: ${picked.path} (${(fileLength / 1024).toStringAsFixed(1)} KB)');

      try {
        debugPrint('[OCR Service] ✂️ Launching ImageCropper...');
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: picked.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Receipt',
              toolbarColor: AppTheme.primary,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppTheme.primary,
              statusBarLight: false,
              navBarLight: true,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
              ],
            ),
            IOSUiSettings(
              title: 'Crop Receipt',
              doneButtonTitle: 'Done',
              cancelButtonTitle: 'Cancel',
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
              ],
            ),
          ],
        );

        if (croppedFile != null) {
          debugPrint('[OCR Service] ✂️ Cropped image ready: ${croppedFile.path}');
          return File(croppedFile.path);
        } else {
          debugPrint('[OCR Service] ✂️ Cropping skipped by user, falling back to original image');
          return File(picked.path);
        }
      } catch (cropErr) {
        debugPrint('[OCR Service] ⚠️ ImageCropper encountered error ($cropErr), falling back to original image');
        return File(picked.path);
      }
    } catch (e, stack) {
      debugPrint('[OCR Service] ❌ Error in pickAndCropImage: $e\n$stack');
      rethrow;
    }
  }

  /// Sends the cropped receipt file to the backend `/ocr/scan-receipt` endpoint.
  Future<OcrParsedData> scanReceiptImage({
    required File image,
    String? walletId,
    required List<ExpenseCategory> availableCategories,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final path = image.path.toLowerCase();
      String mimeType = 'image/jpeg';
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      debugPrint('[OCR Service] 🚀 Sending to API /ocr/scan-receipt: size=${(bytes.length / 1024).toStringAsFixed(1)} KB, mimeType=$mimeType, walletId=$walletId');

      final response = await _client.dio.post(
        '/ocr/scan-receipt',
        data: {
          'image': base64Image,
          'mimeType': mimeType,
          'walletId': walletId,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      debugPrint('[OCR Service] 📩 Received response in ${stopwatch.elapsedMilliseconds}ms: status=${response.statusCode}');

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;

        // Parse amount
        final rawAmount = data['amount'];
        double amount = 0;
        if (rawAmount is num) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is String) {
          amount = double.tryParse(rawAmount) ?? 0;
        }

        // Parse date
        DateTime? parsedDate;
        if (data['date'] != null && data['date'].toString().trim().isNotEmpty) {
          try {
            parsedDate = DateTime.parse(data['date'].toString().trim());
          } catch (_) {}
        }

        // Parse category safely
        ExpenseCategory? parsedCategory;
        final rawCategoryData = data['suggestedCategory'];

        if (rawCategoryData is Map) {
          try {
            final tempCat = ExpenseCategory.fromJson(
              Map<String, dynamic>.from(rawCategoryData),
            );
            parsedCategory = availableCategories.firstWhere(
              (c) => c.id == tempCat.id,
              orElse: () => availableCategories.firstWhere(
                (c) => c.name.toLowerCase() == tempCat.name.toLowerCase(),
                orElse: () => tempCat,
              ),
            );
          } catch (_) {}
        } else if (rawCategoryData is String && rawCategoryData.trim().isNotEmpty) {
          final search = rawCategoryData.toLowerCase().trim();
          try {
            parsedCategory = availableCategories.firstWhere(
              (c) =>
                  c.name.toLowerCase() == search ||
                  c.name.toLowerCase().contains(search),
              orElse: () => availableCategories.firstWhere(
                (c) => c.name.toLowerCase() == 'other',
                orElse: () => availableCategories.isNotEmpty
                    ? availableCategories.first
                    : ExpenseCategory(
                        id: 'temp',
                        name: rawCategoryData.trim(),
                        icon: 'category',
                        color: '#4F46E5',
                      ),
              ),
            );
          } catch (_) {}
        }

        debugPrint('[OCR Service] ✅ Parsed data: amount=$amount, desc=${data['description']}, category=${parsedCategory?.name}, date=$parsedDate');

        return OcrParsedData(
          amount: amount,
          description: data['description'] as String?,
          date: parsedDate,
          category: parsedCategory,
          rawSuggestion: data['rawSuggestion'] as String?,
        );
      } else {
        final message = response.data?['message'] ?? 'Failed to scan receipt';
        debugPrint('[OCR Service] ❌ Server returned unsuccessful response: $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('[OCR Service] ❌ scanReceiptImage error after ${stopwatch.elapsedMilliseconds}ms: $e');
      if (e is DioException) {
        if (e.response?.data != null && e.response!.data is Map) {
          final msg = e.response!.data['message'];
          if (msg != null) throw Exception(msg.toString());
        }
        if (e.response?.statusCode == 422) {
          throw Exception(
            'Could not read the receipt. Please try with a clearer image.',
          );
        } else if (e.response?.statusCode == 500) {
          throw Exception('AI service error. Please try again later.');
        }
        throw Exception(_client.getErrorMessage(e));
      }
      if (e is Exception) rethrow;
      throw Exception('Failed to process receipt: $e');
    }
  }
}
