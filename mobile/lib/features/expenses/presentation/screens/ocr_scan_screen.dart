import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/ocr/ocr_scan_cubit.dart';
import '../bloc/ocr/ocr_scan_state.dart';
import '../widgets/ocr/ocr_bottom_action_bar.dart';
import '../widgets/ocr/ocr_category_picker_sheet.dart';
import '../widgets/ocr/ocr_empty_view.dart';
import '../widgets/ocr/ocr_error_view.dart';
import '../widgets/ocr/ocr_image_preview.dart';
import '../widgets/ocr/ocr_processing_view.dart';
import '../widgets/ocr/ocr_result_preview.dart';
import '../widgets/ocr/ocr_source_picker_sheet.dart';
import '../widgets/ocr/ocr_wallet_selector_card.dart';
import '../widgets/ocr/ocr_wallet_switch_sheet.dart';
import 'expense_entry_screen.dart';

// Re-export OcrScanResult so callers importing this screen file retain full compatibility
export '../../domain/entities/ocr_scan_result.dart';

class OcrScanScreen extends StatefulWidget {
  final WalletEntity? initialWallet;
  const OcrScanScreen({super.key, this.initialWallet});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  late final OcrScanCubit _cubit;
  bool _isSaving = false;
  bool _isPickerOpen = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[OCR Screen] 🏁 Initializing OcrScanScreen');
    _cubit = OcrScanCubit(initialWallet: widget.initialWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashboardState = context.read<DashboardBloc>().state;
      _cubit.initWallet(dashboardState.activeWallet);

      // Safe delayed auto-prompt for source selection:
      // Does not hook into route.animation to avoid navigator locking or semantics collision.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route?.isCurrent == true &&
            _cubit.state.selectedImage == null &&
            !_cubit.state.isProcessing &&
            !_cubit.state.hasResult) {
          debugPrint('[OCR Screen] 🚀 Auto-opening source picker sheet');
          _openSourcePicker();
        }
      });
    });
  }

  @override
  void dispose() {
    debugPrint('[OCR Screen] 🛑 Disposing OcrScanScreen');
    _cubit.close();
    super.dispose();
  }

  void _openManualInput() {
    debugPrint('[OCR Screen] ✍️ Navigating to Manual Expense Entry');
    final dashboardState = context.read<DashboardBloc>().state;
    final effectiveWallet = _cubit.state.activeWallet ?? dashboardState.activeWallet;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseEntryScreen(initialWallet: effectiveWallet),
      ),
    );
  }

  Future<void> _openSourcePicker() async {
    if (!mounted || _isPickerOpen) {
      debugPrint('[OCR Screen] ⚠️ Source picker skipped (mounted=$mounted, isOpen=$_isPickerOpen)');
      return;
    }
    _isPickerOpen = true;
    debugPrint('[OCR Screen] 📂 Opening source picker sheet');

    try {
      final categories = context.read<DashboardBloc>().state.categories;
      await OcrSourcePickerSheet.show(
        context: context,
        onSourceSelected: (source) {
          if (!mounted) return;
          debugPrint('[OCR Screen] 📸 Source selected: $source');
          _cubit.pickAndProcessImage(
            source: source,
            availableCategories: categories,
          );
        },
        onManualInput: _openManualInput,
      );
    } catch (e, stack) {
      debugPrint('[OCR Screen] ❌ Error displaying source picker: $e\n$stack');
    } finally {
      if (mounted) {
        _isPickerOpen = false;
      }
    }
  }

  void _openWalletSwitchSheet() {
    debugPrint('[OCR Screen] 🔄 Opening wallet switch sheet');
    final dashboardState = context.read<DashboardBloc>().state;
    OcrWalletSwitchSheet.show(
      context: context,
      activeWallet: _cubit.state.activeWallet ?? dashboardState.activeWallet,
      personalWallets: dashboardState.personalWallets,
      sharedWallets: dashboardState.sharedWallets,
      onWalletSelected: (wallet) {
        debugPrint('[OCR Screen] 💼 Selected wallet: ${wallet.name}');
        _cubit.switchWallet(wallet);
        context.read<DashboardBloc>().add(DashboardSelectWalletRequested(wallet));
      },
    );
  }

  Future<void> _confirmResult() async {
    if (_isSaving) return;

    final state = _cubit.state;
    final amount = state.amount;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }

    final dashboardBloc = context.read<DashboardBloc>();
    final categories = dashboardBloc.state.categories;

    // Ensure a category is selected
    var category = state.category;
    if (category == null) {
      if (categories.isNotEmpty) {
        // Prompt category selection
        await OcrCategoryPickerSheet.show(
          context: context,
          selectedCategory: null,
          categories: categories,
          onCategorySelected: (cat) {
            _cubit.updateCategory(cat);
            category = cat;
          },
        );
        category = _cubit.state.category;
      }
      if (category == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category first')),
          );
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final effectiveWallet = state.activeWallet ?? dashboardBloc.state.activeWallet;
      debugPrint('[OCR Screen] 💾 Saving transaction: amount=$amount, category=${category!.name}, wallet=${effectiveWallet?.name}');

      final newExpense = ExpenseEntity(
        id: 'new_exp_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        description: state.description?.trim().isEmpty == true
            ? null
            : state.description?.trim(),
        date: state.date ?? DateTime.now(),
        type: ExpenseType.nonRoutine,
        userId: 'user1',
        walletId: effectiveWallet?.id ?? 'personal_w1',
        category: category!,
        creatorName: 'User',
      );

      final completer = Completer<bool>();
      dashboardBloc.add(DashboardAddExpenseRequested(newExpense, completer));
      final success = await completer.future;

      debugPrint('[OCR Screen] 💾 Save transaction result: success=$success');
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Transaction saved successfully!'),
              ],
            ),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save transaction. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('[OCR Screen] ❌ Exception while saving transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<OcrScanCubit, OcrScanState>(
        builder: (context, state) {
          final responsive = ResponsiveHelper(context);
          final dashboardState = context.watch<DashboardBloc>().state;
          final effectiveWallet =
              state.activeWallet ?? dashboardState.activeWallet;
          final currencyCode = effectiveWallet?.currency ?? 'IDR';
          final currencySymbol =
              CurrencyHelper.getFormatter(currencyCode).currencySymbol.trim();
          final bool showBottomBar = state.hasResult && !state.isProcessing;

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
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.darkSlateVariant,
                ),
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
                // Manual input action in AppBar
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  onPressed: _openManualInput,
                  tooltip: 'Manual Input',
                ),
                if (state.selectedImage != null && !state.isProcessing)
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
                    onPressed: _openSourcePicker,
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
                        // ── Target Wallet Banner ──
                        OcrWalletSelectorCard(
                          activeWallet: effectiveWallet,
                          hasMultipleWallets:
                              dashboardState.allWallets.length > 1,
                          onSwitchTap: _openWalletSwitchSheet,
                        ),

                        // ── Image Preview ──
                        if (state.selectedImage != null)
                          OcrImagePreview(
                            imageFile: state.selectedImage!,
                            isProcessing: state.isProcessing,
                            hasResult: state.hasResult,
                          ),

                        // ── Processing State ──
                        if (state.isProcessing) const OcrProcessingView(),

                        // ── Error State ──
                        if (state.errorMessage != null && !state.isProcessing)
                          OcrErrorView(
                            errorMessage: state.errorMessage!,
                            onRetry: () {
                              _cubit.retryCurrentProcess(
                                availableCategories: dashboardState.categories,
                              );
                            },
                            onNewPhoto: _openSourcePicker,
                          ),

                        // ── Result Preview ──
                        if (state.hasResult && !state.isProcessing)
                          OcrResultPreview(
                            amount: state.amount,
                            description: state.description,
                            category: state.category,
                            rawSuggestion: state.rawSuggestion,
                            date: state.date,
                            currencyCode: currencyCode,
                            currencySymbol: currencySymbol,
                            availableCategories: dashboardState.categories,
                            onCategoryChanged: _cubit.updateCategory,
                          ),

                        // ── Empty State (no image selected) ──
                        if (state.selectedImage == null && !state.isProcessing)
                          OcrEmptyView(
                            onSelectReceipt: _openSourcePicker,
                            onManualInput: _openManualInput,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: showBottomBar
                ? OcrBottomActionBar(
                    onRetake: _openSourcePicker,
                    onConfirm: _confirmResult,
                    isSaving: _isSaving,
                  )
                : null,
          );
        },
      ),
    );
  }
}
