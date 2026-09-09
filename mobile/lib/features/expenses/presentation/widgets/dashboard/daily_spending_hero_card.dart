import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';

class DailySpendingHeroCard extends StatelessWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;

  const DailySpendingHeroCard({
    super.key,
    required this.provider,
    required this.responsive,
    required this.formatter,
  });

  void _showSetBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SetDailyBudgetDialog(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double budgetLimit = provider.activeWallet?.dailyBudget ?? 0.0;
    final double spendToday = provider.todaySpend;
    final double budgetPercent = budgetLimit <= 0
        ? 0.0
        : (spendToday > budgetLimit ? 1.0 : (spendToday / budgetLimit));

    return Container(
      decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
      child: ClipRRect(
        borderRadius: AppTheme.roundedBorder,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.primary, width: 4.0),
            ),
          ),
          child: Stack(
            children: [
              // Subtle Background Graphic
              Positioned(
                top: -48,
                right: -48,
                width: 192,
                height: 192,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(8), // ~3% opacity
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S SPENDING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(12),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlateVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(spendToday),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(32),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showSetBudgetDialog(context),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Daily Budget',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: AppTheme.darkSlateVariant,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.edit,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                            ],
                          ),
                          Text(
                            budgetLimit > 0
                                ? formatter.format(budgetLimit)
                                : 'Tap to set',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: budgetPercent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetDailyBudgetDialog extends StatefulWidget {
  final DashboardState provider;

  const SetDailyBudgetDialog({super.key, required this.provider});

  @override
  State<SetDailyBudgetDialog> createState() => _SetDailyBudgetDialogState();
}

class _SetDailyBudgetDialogState extends State<SetDailyBudgetDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.provider.activeWallet?.dailyBudget != null
          ? widget.provider.activeWallet!.dailyBudget!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final double? newBudget = double.tryParse(_controller.text.trim());
    if (newBudget != null && newBudget >= 0) {
      setState(() {
        _isSaving = true;
      });
      try {
        final completer = Completer<bool>();
        context.read<DashboardBloc>().add(
          DashboardUpdateDailyBudgetRequested(newBudget, completer),
        );
        final success = await completer.future;
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Daily budget updated!' : 'Failed to update budget.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Daily Budget Limit',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set your daily target limit. A realistic budget helps you optimize your savings automatically.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            enabled: !_isSaving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.darkSlate,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
              prefixText: 'Rp ',
              prefixStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 16,
              ),
              hintText: 'e.g. 150,000',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save Limit',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
