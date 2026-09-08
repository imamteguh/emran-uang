import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/ocr_scan_result.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/expense_entry/expense_entry_cubit.dart';
import '../bloc/expense_entry/expense_entry_state.dart';
import '../widgets/expense_entry/expense_amount_card.dart';
import '../widgets/expense_entry/expense_category_selector.dart';
import '../widgets/expense_entry/expense_date_selector.dart';
import '../widgets/expense_entry/expense_entry_app_bar.dart';
import '../widgets/expense_entry/expense_note_field.dart';
import '../widgets/expense_entry/expense_routine_toggle.dart';
import '../widgets/expense_entry/expense_save_button.dart';
import '../widgets/expense_entry/expense_shared_members_card.dart';
import 'main_shell.dart';

// Re-export CurrencyInputFormatter for backward compatibility with existing callers
export '../widgets/expense_entry/currency_input_formatter.dart';

class ExpenseEntryScreen extends StatefulWidget {
  final DateTime? initialDate;
  final ExpenseCategory? initialCategory;
  final WalletEntity? initialWallet;
  final OcrScanResult? initialOcrResult;
  final ExpenseEntryCubit? cubit;

  const ExpenseEntryScreen({
    super.key,
    this.initialDate,
    this.initialCategory,
    this.initialWallet,
    this.initialOcrResult,
    this.cubit,
  });

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  late final ExpenseEntryCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ??
        ExpenseEntryCubit(
          initialDate: widget.initialDate,
          initialCategory: widget.initialCategory,
          initialWallet: widget.initialWallet,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardBloc = context.read<DashboardBloc>();
      dashboardBloc.add(const DashboardFetchCategoriesRequested());

      if (widget.initialWallet != null) {
        dashboardBloc.add(DashboardSelectWalletRequested(widget.initialWallet!));
      }

      final dashboardState = dashboardBloc.state;
      _cubit.initWallet(widget.initialWallet ?? dashboardState.activeWallet);
      _cubit.syncCategories(dashboardState.categories);

      if (widget.initialOcrResult != null) {
        _handleOcrResult(widget.initialOcrResult!);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _handleOcrResult(OcrScanResult result) {
    try {
      final dashboardBloc = context.read<DashboardBloc>();
      final dashboardState = dashboardBloc.state;

      if (result.wallet != null &&
          result.wallet!.id != dashboardState.activeWallet?.id) {
        dashboardBloc.add(DashboardSelectWalletRequested(result.wallet!));
      }

      _cubit.applyOcrResult(
        result,
        dashboardState.categories,
        currentActiveWallet: dashboardState.activeWallet,
      );

      final state = _cubit.state;
      if (state.formattedAmount != null) {
        _amountController.value = TextEditingValue(
          text: state.formattedAmount!,
          selection: TextSelection.collapsed(offset: state.formattedAmount!.length),
        );
      }
      if (state.initialDescription != null &&
          state.initialDescription!.isNotEmpty) {
        _descController.value = TextEditingValue(
          text: state.initialDescription!,
          selection: TextSelection.collapsed(
            offset: state.initialDescription!.length,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.wallet != null
                        ? 'Receipt data applied for ${result.wallet!.name}!'
                        : 'Receipt data applied! Review and save.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF246A52),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error applying OCR result: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (_cubit.state.isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      final dashboardBloc = context.read<DashboardBloc>();
      final success = await _cubit.submitExpense(
        dashboardBloc: dashboardBloc,
        amountText: _amountController.text,
        descriptionText: _descController.text,
      );

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

        // Direct directly to Dashboard after transaction is saved
        MainShellScreen.navigateToDashboard(context);
      } else {
        final error = _cubit.state.errorMessage ??
            'Failed to save transaction. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final dashboardBloc = context.watch<DashboardBloc>();
    final dashboardState = dashboardBloc.state;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ExpenseEntryCubit, ExpenseEntryState>(
        builder: (context, state) {
          final displayCategories = dashboardState.categories;
          _cubit.syncCategories(displayCategories);

          final effectiveWallet = state.activeWallet ?? dashboardState.activeWallet;
          final currencyCode = effectiveWallet?.currency ?? 'IDR';
          final currencySymbol =
              CurrencyHelper.getFormatter(currencyCode).currencySymbol;

          final double cardWidth =
              responsive.isTablet || responsive.isDesktop ? 480 : double.infinity;

          return Scaffold(
            appBar: ExpenseEntryAppBar(
              activeWallet: effectiveWallet,
              personalWallets: dashboardState.personalWallets,
              sharedWallets: dashboardState.sharedWallets,
              isSharedMode: dashboardState.isSharedMode,
              onWalletSelected: (wallet) {
                dashboardBloc.add(DashboardSelectWalletRequested(wallet));
                _cubit.switchWallet(wallet);
              },
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: responsive.screenPadding,
                child: Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Amount Input Card
                          ExpenseAmountCard(
                            controller: _amountController,
                            currencyCode: currencyCode,
                            currencySymbol: currencySymbol,
                          ),
                          const SizedBox(height: 32),

                          // Category Selector Grid
                          ExpenseCategorySelector(
                            categories: displayCategories,
                            selectedCategory: state.selectedCategory,
                            onCategorySelected: _cubit.updateCategory,
                          ),
                          const SizedBox(height: 32),

                          // Date & Time Selector
                          ExpenseDateSelector(
                            selectedDate: state.selectedDate,
                            onDateChanged: _cubit.updateDate,
                            onTimeChanged: (time, {targetDate}) =>
                                _cubit.updateTime(time, targetDate: targetDate),
                          ),
                          const SizedBox(height: 32),

                          // Transaction Note / Description Field
                          ExpenseNoteField(
                            controller: _descController,
                          ),
                          const SizedBox(height: 24),

                          // Routine Expense Toggle
                          ExpenseRoutineToggle(
                            isRoutine: state.isRoutine,
                            onChanged: _cubit.updateRoutine,
                          ),
                          const SizedBox(height: 16),

                          // Shared Group Members (only in shared mode)
                          if (dashboardState.isSharedMode) ...[
                            ExpenseSharedMembersCard(
                              members: effectiveWallet?.groupMembers,
                            ),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 20),

                          // Save Action Button
                          ExpenseSaveButton(
                            isSaving: state.isSubmitting,
                            onPressed: _handleSubmit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
