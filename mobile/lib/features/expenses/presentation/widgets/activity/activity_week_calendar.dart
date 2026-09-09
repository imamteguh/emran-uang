import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';

class ActivityWeekCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> weekDates;
  final List<ExpenseEntity> allExpenses;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const ActivityWeekCalendar({
    super.key,
    required this.selectedDate,
    required this.weekDates,
    required this.allExpenses,
    required this.onSelectDate,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  bool _hasTransaction(DateTime date) {
    return allExpenses.any(
      (expense) =>
          expense.date.year == date.year &&
          expense.date.month == date.month &&
          expense.date.day == date.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month & Navigation Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.darkSlate,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onPreviousWeek,
                  icon: const Icon(Icons.chevron_left_rounded),
                  splashRadius: 20,
                ),
                IconButton(
                  onPressed: onNextWeek,
                  icon: const Icon(Icons.chevron_right_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal Calendar Bar (7 Columns)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDates.map((date) {
            final isSelected =
                date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;
            final isToday =
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;
            final hasTx = _hasTransaction(date);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () => onSelectDate(date),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : (isToday
                              ? AppTheme.primary.withAlpha(20)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : (isToday
                                ? AppTheme.primary.withAlpha(80)
                                : Colors.grey[200]!),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? AppTheme.cardShadow : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 3),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('d').format(date),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Dot indicator
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasTx
                                ? (isSelected
                                    ? Colors.white
                                    : AppTheme.primary)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
