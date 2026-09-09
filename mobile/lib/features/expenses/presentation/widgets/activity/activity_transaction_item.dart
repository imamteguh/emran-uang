import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/wallet.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';

class ActivityTransactionItem extends StatelessWidget {
  final ExpenseEntity expense;
  final DashboardState provider;
  final String? currentUserId;
  final NumberFormat currencyFormatter;
  final VoidCallback onDelete;

  const ActivityTransactionItem({
    super.key,
    required this.expense,
    required this.provider,
    required this.currentUserId,
    required this.currencyFormatter,
    required this.onDelete,
  });

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Activity',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this activity? This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.darkSlateVariant,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.darkSlateVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final isPersonalWallet = provider.activeWallet?.type == WalletType.personal;
    final isCreator = currentUserId != null && expense.userId == currentUserId;
    final isOwner = isPersonalWallet || isCreator || expense.userId.isEmpty;
    final isMe = expense.userId == currentUserId;
    final catColor = AppTheme.parseHexColor(expense.category.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('activity_${expense.id}'),
        direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: AppTheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (!isOwner) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Hanya pembuat transaksi yang dapat menghapus transaksi ini',
                ),
                backgroundColor: AppTheme.error,
              ),
            );
            return false;
          }
          return await _showDeleteConfirmationDialog(context);
        },
        onDismissed: (_) => onDelete(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: catColor.withAlpha(30),
                child: CategoryIcon(
                  icon: expense.category.icon,
                  color: catColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description ?? expense.category.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(expense.date),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                        const Text(
                          '•',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            expense.category.name,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (provider.isSharedMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFFE0E7FF)
                                  : const Color(0xFFFCE7F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMe
                                      ? Icons.person_rounded
                                      : Icons.person_outline_rounded,
                                  size: 11,
                                  color: isMe
                                      ? const Color(0xFF4338CA)
                                      : const Color(0xFFBE185D),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isMe
                                      ? 'You'
                                      : (expense.creatorName.isNotEmpty
                                          ? expense.creatorName
                                          : 'Partner'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isMe
                                        ? const Color(0xFF4338CA)
                                        : const Color(0xFFBE185D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${currencyFormatter.format(expense.amount)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkSlate,
                      fontSize: 15,
                    ),
                  ),
                  if (provider.isSharedMode) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.blue.withAlpha(20)
                            : Colors.pink.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMe
                              ? Colors.blue.withAlpha(60)
                              : Colors.pink.withAlpha(60),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isMe
                            ? 'ME'
                            : (expense.creatorName.length >= 2
                                ? expense.creatorName
                                    .substring(0, 2)
                                    .toUpperCase()
                                : (expense.creatorName.isNotEmpty
                                    ? expense.creatorName.toUpperCase()
                                    : 'SO')),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.blue[800] : Colors.pink[800],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
