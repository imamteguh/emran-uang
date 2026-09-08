import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/currency_helper.dart';
import 'currency_input_formatter.dart';

class ExpenseAmountCard extends StatelessWidget {
  final TextEditingController controller;
  final String currencyCode;
  final String currencySymbol;
  final FormFieldValidator<String>? validator;

  const ExpenseAmountCard({
    super.key,
    required this.controller,
    required this.currencyCode,
    required this.currencySymbol,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = CurrencyHelper.getFormatter(currencyCode);
    final decimalDigits = formatter.decimalDigits ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'ENTER AMOUNT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currencySymbol.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: [
                    CurrencyInputFormatter(formatter),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: decimalDigits == 0 ? '0' : '0.00',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary.withAlpha(70),
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textAlign: TextAlign.left,
                  validator: validator ??
                      (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        return null;
                      },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
