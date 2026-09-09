import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/currency_helper.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/expense.dart';
import '../category_icon.dart';
import 'chat_message.dart';

class AiChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ResponsiveHelper responsive;
  final String currencyCode;

  const AiChatBubble({
    super.key,
    required this.message,
    required this.responsive,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.user:
        return _buildUserBubble();
      case ChatMessageType.ai:
        return _buildAiBubble();
      case ChatMessageType.system:
        return _buildSystemBubble();
    }
  }

  Widget _buildUserBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 48),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble() {
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);
    final hasSaved = message.saved && message.savedExpense != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withAlpha(128),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onBackground,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (hasSaved) ...[
                  const SizedBox(height: 8),
                  _buildSavedExpenseCard(
                    message.savedExpense!,
                    currencyFormatter,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSystemBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withAlpha(25),
              width: 1,
            ),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedExpenseCard(
    ExpenseEntity expense,
    NumberFormat currencyFormatter,
  ) {
    final catColor = AppTheme.parseHexColor(expense.category.color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondary.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CategoryIcon(
                icon: expense.category.icon,
                color: catColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description ?? 'Expense',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.onBackground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${currencyFormatter.format(expense.amount)} · ${expense.category.name} · ${DateFormat('HH:mm').format(expense.date)}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.secondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
