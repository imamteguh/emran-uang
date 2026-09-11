import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/currency_helper.dart';
import '../../bloc/expense_entry/expense_entry_cubit.dart';
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

  void _addAmount(double increment) {
    final current =
        ExpenseEntryCubit.parseRawAmount(controller.text, currencyCode) ?? 0.0;
    final newAmount = current + increment;
    final formatted =
        ExpenseEntryCubit.formatAmountForInput(newAmount, currencyCode);
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _clearAmount() {
    controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = CurrencyHelper.getFormatter(currencyCode);
    final decimalDigits = formatter.decimalDigits ?? 0;
    final isIdr = currencyCode.toUpperCase() == 'IDR';

    final presets = isIdr
        ? <Map<String, dynamic>>[
            {'label': '+10rb', 'value': 10000.0},
            {'label': '+20rb', 'value': 20000.0},
            {'label': '+50rb', 'value': 50000.0},
            {'label': '+100rb', 'value': 100000.0},
          ]
        : <Map<String, dynamic>>[
            {'label': '+5', 'value': 5.0},
            {'label': '+10', 'value': 10.0},
            {'label': '+20', 'value': 20.0},
            {'label': '+50', 'value': 50.0},
          ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Label & Reset Button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasValue = value.text.trim().isNotEmpty;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NOMINAL PENGELUARAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppTheme.darkSlateVariant,
                        ),
                      ),
                    ],
                  ),
                  if (hasValue)
                    InkWell(
                      onTap: _clearAmount,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.restart_alt_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Currency Badge & Big Amount Input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(40),
                    width: 1,
                  ),
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
                    fontSize: 34,
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
                      color: AppTheme.primary.withAlpha(60),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textAlign: TextAlign.left,
                  validator: validator ??
                      (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nominal pengeluaran wajib diisi';
                        }
                        final parsed = ExpenseEntryCubit.parseRawAmount(
                            val, currencyCode);
                        if (parsed == null || parsed <= 0) {
                          return 'Nominal harus lebih dari 0';
                        }
                        return null;
                      },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider subtle
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Quick Preset Chips (+10rb, +20rb, +50rb, +100rb)
          Row(
            children: presets.map((item) {
              final label = item['label'] as String;
              final val = item['value'] as double;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _addAmount(val),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
