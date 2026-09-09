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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final catColor = AppTheme.parseHexColor(expense.category.color);

        final isPersonalWallet =
            provider.activeWallet?.type == WalletType.personal;
        final isCreator =
            currentUserId != null && expense.userId == currentUserId;
        final isOwner = isPersonalWallet || isCreator || expense.userId.isEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(expense.id),
            direction:
                isOwner ? DismissDirection.endToStart : DismissDirection.none,
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
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: catColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: CategoryIcon(
                      icon: expense.category.icon,
                      color: catColor,
                      size: 22,
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
                            fontSize: 15,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(expense.date),
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AppTheme.darkSlateVariant,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${formatter.format(expense.amount)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkSlate,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: expense.userId == currentUserId
                              ? Colors.blue[100]
                              : Colors.pink[100],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        alignment: Alignment.center,
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
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          const Text('🐷', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No activity recorded yet',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSharedMode
                ? 'No expenses recorded in the shared wallet yet.'
                : 'Ketik pesan ke AI atau tap tombol "+" untuk mencatat.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
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
              side: BorderSide(color: AppTheme.primary.withAlpha(80)),
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
