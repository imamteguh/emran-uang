import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/wallet.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';
import '../../screens/ai_chat_screen.dart';
import '../category_icon.dart';

class DashboardActivityFeed extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;
  final String? currentUserId;
  final DashboardState provider;

  const DashboardActivityFeed({
    super.key,
    required this.expenses,
    required this.responsive,
    required this.formatter,
    required this.currentUserId,
    required this.provider,
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
    if (expenses.isEmpty) {
      return DashboardEmptyState(isSharedMode: provider.isSharedMode);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expenses.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: 16,
            color: Color(0xFFF1F5F9),
          ),
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final catColor = AppTheme.parseHexColor(expense.category.color);

            final isPersonalWallet =
                provider.activeWallet?.type == WalletType.personal;
            final isCreator =
                currentUserId != null && expense.userId == currentUserId;
            final isOwner = isPersonalWallet || isCreator || expense.userId.isEmpty;

            return Dismissible(
              key: Key(expense.id),
              direction:
                  isOwner ? DismissDirection.endToStart : DismissDirection.none,
              background: Container(
                padding: const EdgeInsets.only(right: 20),
                alignment: Alignment.centerRight,
                color: AppTheme.error,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
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
              onDismissed: (_) {
                context.read<DashboardBloc>().add(
                      DashboardDeleteExpenseRequested(
                        expense.id,
                        Completer<bool>(),
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: CategoryIcon(
                        icon: expense.category.icon,
                        color: catColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.description?.isNotEmpty == true
                                ? expense.description!
                                : expense.category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                DateFormat('hh:mm a').format(expense.date),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                expense.category.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '-${formatter.format(expense.amount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkSlate,
                            fontSize: 14,
                          ),
                        ),
                        if (provider.isSharedMode || expense.userId.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: expense.userId == currentUserId
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFFDF2F8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              expense.userId == currentUserId
                                  ? 'ME'
                                  : (expense.creatorName.length >= 2
                                      ? expense.creatorName
                                          .substring(0, 2)
                                          .toUpperCase()
                                      : (expense.creatorName.isNotEmpty
                                          ? expense.creatorName.toUpperCase()
                                          : 'SO')),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: expense.userId == currentUserId
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFDB2777),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  final bool isSharedMode;

  const DashboardEmptyState({super.key, required this.isSharedMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No activity recorded yet',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSharedMode
                ? 'No expenses recorded in the shared wallet yet.'
                : 'Ketik pesan ke AI atau tap tombol "+" untuk mencatat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
            icon: const Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: AppTheme.primary,
            ),
            label: Text(
              'Coba Catat via AI Chat',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
