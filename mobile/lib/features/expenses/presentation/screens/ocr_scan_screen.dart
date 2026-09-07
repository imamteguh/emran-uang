import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/expense.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/category_icon.dart';

/// Result data from OCR scanning, passed back to ExpenseEntryScreen.
class OcrScanResult {
  final double amount;
  final String? description;
  final DateTime? date;
  final ExpenseCategory? category;

  const OcrScanResult({
    required this.amount,
    this.description,
    this.date,
    this.category,
  });
}

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final DioClient _client = DioClient();

  // States
  File? _selectedImage;
  bool _isProcessing = false;
  bool _hasResult = false;
  String? _errorMessage;

  // OCR Result fields (editable)
  double? _resultAmount;
  String? _resultDescription;
  DateTime? _resultDate;
  ExpenseCategory? _resultCategory;
  String? _rawSuggestion;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Show source picker on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showImageSourcePicker();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Image Source Picker ──────────────────────────────────────────────────

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Scan Receipt',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a source for your receipt image',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        subtitle: 'Take a photo',
                        color: AppTheme.primary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSourceOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        subtitle: 'Choose photo',
                        color: AppTheme.secondary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(40), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: AppTheme.darkSlateVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image Picking & Cropping ────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) return;

      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppTheme.primary,
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
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
          _errorMessage = null;
          _hasResult = false;
        });
        _processImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  // ── AI Processing ───────────────────────────────────────────────────────

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _hasResult = false;
    });

    try {
      // Read image and convert to base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine MIME type
      final path = _selectedImage!.path.toLowerCase();
      String mimeType = 'image/jpeg';
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      // Call backend OCR endpoint
      final response = await _client.dio.post(
        '/ocr/scan-receipt',
        data: {
          'image': base64Image,
          'mimeType': mimeType,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];

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
        if (data['date'] != null && data['date'].toString().isNotEmpty) {
          try {
            parsedDate = DateTime.parse(data['date']);
          } catch (_) {}
        }

        // Parse category
        ExpenseCategory? parsedCategory;
        if (data['suggestedCategory'] != null) {
          parsedCategory = ExpenseCategory.fromJson(
            data['suggestedCategory'] as Map<dynamic, dynamic>,
          );
        }

        setState(() {
          _resultAmount = amount;
          _resultDescription = data['description'];
          _resultDate = parsedDate;
          _resultCategory = parsedCategory;
          _rawSuggestion = data['rawSuggestion'];
          _hasResult = true;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to scan receipt';
          _isProcessing = false;
        });
      }
    } catch (e) {
      String errorMsg = 'Failed to process receipt';
      if (e is DioException && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map && resData['message'] != null) {
          errorMsg = resData['message'].toString();
        }
      } else if (e.toString().contains('422')) {
        errorMsg = 'Could not read the receipt. Please try with a clearer image.';
      } else if (e.toString().contains('500')) {
        errorMsg = 'AI service error. Please try again later.';
      }
      setState(() {
        _errorMessage = errorMsg;
        _isProcessing = false;
      });
    }
  }

  // ── Confirm and return result ───────────────────────────────────────────

  void _confirmResult() {
    if (_resultAmount == null || _resultAmount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }

    final result = OcrScanResult(
      amount: _resultAmount!,
      description: _resultDescription,
      date: _resultDate,
      category: _resultCategory,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final provider = context.watch<DashboardBloc>().state;
    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencySymbol =
        CurrencyHelper.getFormatter(currencyCode).currencySymbol.trim();
    final bool showBottomBar = _hasResult && !_isProcessing;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF7F9FB),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.darkSlateVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Scan Receipt',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          if (_selectedImage != null && !_isProcessing)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.secondary,
                  size: 18,
                ),
              ),
              onPressed: _showImageSourcePicker,
              tooltip: 'Retake',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: !showBottomBar,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            responsive.screenPadding.left,
            8,
            responsive.screenPadding.right,
            showBottomBar ? 24 : (responsive.screenPadding.bottom + 16),
          ),
          child: Center(
            child: SizedBox(
              width: responsive.isTablet || responsive.isDesktop
                  ? 480
                  : double.infinity,
              child: Column(
                children: [
                  // ── Image Preview ──────────────────────────────
                  if (_selectedImage != null) _buildImagePreview(),

                  // ── Processing State ───────────────────────────
                  if (_isProcessing) _buildProcessingState(),

                  // ── Error State ────────────────────────────────
                  if (_errorMessage != null) _buildErrorState(),

                  // ── Result Preview ─────────────────────────────
                  if (_hasResult && !_isProcessing)
                    _buildResultPreview(currencySymbol, currencyCode, provider),

                  // ── Empty State (no image selected) ────────────
                  if (_selectedImage == null && !_isProcessing)
                    _buildEmptyState(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          showBottomBar ? _buildBottomActionBar(responsive) : null,
    );
  }

  // ── UI Components ─────────────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(60),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Status badge
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? AppTheme.primary.withAlpha(220)
                      : _hasResult
                          ? AppTheme.secondary.withAlpha(220)
                          : Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        _hasResult
                            ? Icons.check_circle_rounded
                            : Icons.image_rounded,
                        size: 14,
                        color: _hasResult
                            ? Colors.white
                            : AppTheme.darkSlateVariant,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _isProcessing
                          ? 'Scanning...'
                          : _hasResult
                              ? 'Scanned'
                              : 'Receipt',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isProcessing || _hasResult
                            ? Colors.white
                            : AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.primary.withAlpha(30),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Animated scanning icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withAlpha(30),
                        AppTheme.primary.withAlpha(10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withAlpha(20),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(60),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'AI is reading your receipt...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Extracting amount, description, date, and category',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppTheme.darkSlateVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: AppTheme.primary.withAlpha(20),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.error.withAlpha(40), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processImage,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showImageSourcePicker,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(
                    'New Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultPreview(
    String currencySymbol,
    String currencyCode,
    dynamic provider,
  ) {
    final categories = provider.categories as List<ExpenseCategory>;
    final formatter = CurrencyHelper.getFormatter(currencyCode);

    return Column(
      children: [
        // ── Success header ──
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.secondary.withAlpha(15),
                AppTheme.primary.withAlpha(10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppTheme.secondary.withAlpha(40), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Extraction Complete',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    Text(
                      'Review the details below and confirm',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Amount Card ──
        _buildResultCard(
          icon: Icons.payments_rounded,
          iconColor: AppTheme.primary,
          label: 'AMOUNT',
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currencySymbol,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formatter.format(_resultAmount ?? 0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Description Card ──
        _buildResultCard(
          icon: Icons.description_rounded,
          iconColor: AppTheme.tertiary,
          label: 'DESCRIPTION',
          child: Text(
            _resultDescription ?? 'No description',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: _resultDescription != null
                  ? AppTheme.darkSlate
                  : Colors.grey,
              fontStyle: _resultDescription != null
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ),

        // ── Category Card ──
        _buildResultCard(
          icon: Icons.category_rounded,
          iconColor: AppTheme.secondary,
          label: 'CATEGORY',
          trailing: _buildCategorySelector(categories),
          child: Row(
            children: [
              if (_resultCategory != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        _resultCategory!.color.replaceFirst('#', '0xFF'),
                      ),
                    ).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CategoryIcon(
                      icon: _resultCategory!.icon,
                      color: Color(
                        int.parse(
                          _resultCategory!.color.replaceFirst('#', '0xFF'),
                        ),
                      ),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _resultCategory!.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ] else
                Text(
                  _rawSuggestion ?? 'Unknown',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // ── Date Card ──
        _buildResultCard(
          icon: Icons.calendar_today_rounded,
          iconColor: AppTheme.tertiary,
          label: 'DATE',
          child: Text(
            _resultDate != null
                ? DateFormat('EEEE, d MMMM yyyy • HH:mm').format(_resultDate!)
                : 'Not detected (will use today)',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: _resultDate != null ? AppTheme.darkSlate : Colors.grey,
              fontStyle:
                  _resultDate != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),

        // ── Tips Note ──
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verify the extracted details above. Tap "Use This Data" below to import into your transaction.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Bottom Action Bar (Fixed at bottom with SafeArea) ───────────────────

  Widget _buildBottomActionBar(ResponsiveHelper responsive) {
    final double contentWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _showImageSourcePicker,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: Text(
                      'Retake',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.darkSlateVariant,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _confirmResult,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        'Use This Data',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shadowColor: AppTheme.primary.withAlpha(76),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCategorySelector(List<ExpenseCategory> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _showCategoryPicker(categories),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, size: 12, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              'Change',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(List<ExpenseCategory> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Text(
                        'Select Category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          4,
                          20,
                          24 + MediaQuery.of(context).padding.bottom,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _resultCategory?.id == cat.id;
                        final color = Color(
                          int.parse(cat.color.replaceFirst('#', '0xFF')),
                        );

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _resultCategory = cat;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withAlpha(25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : const Color(0xFFF1F5F9),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: cat.icon,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Text(
                                    cat.name,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? color
                                          : AppTheme.darkSlateVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 36),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No receipt selected',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or choose from gallery\nto automatically fill your transaction',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _showImageSourcePicker,
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: Text(
              'Select Receipt',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              shape: const StadiumBorder(),
              elevation: 3,
              shadowColor: AppTheme.primary.withAlpha(76),
            ),
          ),
        ],
      ),
    );
  }
}
