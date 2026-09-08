import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';

class ExpenseDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final Function(TimeOfDay time, {DateTime? targetDate}) onTimeChanged;

  const ExpenseDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _selectTime(BuildContext context, {DateTime? targetDate}) async {
    final baseDate = targetDate ?? selectedDate;
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(selectedDate);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.darkSlate,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppTheme.primary.withAlpha(35)
                    : const Color(0xFFF1F5F9),
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppTheme.primary
                    : AppTheme.darkSlate,
              ),
              dialHandColor: AppTheme.primary,
              dialBackgroundColor: const Color(0xFFF1F5F9),
              dialTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : AppTheme.darkSlate,
              ),
              entryModeIconColor: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onTimeChanged(picked, targetDate: baseDate);
    } else if (targetDate != null) {
      // User picked date but cancelled time picker dialog, preserve current time
      onTimeChanged(
        TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute),
        targetDate: baseDate,
      );
    }
  }

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppTheme.interactiveShadow : AppTheme.softShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.darkSlateVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateButton(BuildContext context) {
    final isToday = _isSameDay(selectedDate, DateTime.now());
    final isYesterday = _isSameDay(
      selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final isQuickSelect = isToday || isYesterday;
    final String formattedDate = DateFormat('EEE, d MMM yyyy').format(selectedDate);

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppTheme.darkSlate,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          if (!context.mounted) return;
          await _selectTime(context, targetDate: picked);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: !isQuickSelect ? AppTheme.primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isQuickSelect ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: !isQuickSelect ? 2.0 : 1.0,
          ),
          boxShadow: !isQuickSelect ? AppTheme.interactiveShadow : AppTheme.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: !isQuickSelect ? AppTheme.primary : AppTheme.darkSlateVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isQuickSelect ? 'Other Date...' : formattedDate,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: !isQuickSelect ? FontWeight.bold : FontWeight.normal,
                  color: !isQuickSelect ? AppTheme.primary : AppTheme.darkSlateVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelectorCard(BuildContext context) {
    final isYesterday = _isSameDay(
      selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final dateLabel = isYesterday
        ? 'Yesterday'
        : DateFormat('EEE, d MMM').format(selectedDate);
    final timeFormatted = DateFormat('hh:mm a').format(selectedDate);

    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withAlpha(50),
            width: 1.5,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.access_time_filled_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Time ($dateLabel)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlateVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeFormatted,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Change',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Date',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.darkSlateVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateChip(
                label: 'Today',
                isSelected: isToday,
                onTap: () {
                  onDateChanged(DateTime.now());
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateChip(
                label: 'Yesterday',
                isSelected: _isSameDay(
                  selectedDate,
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final yesterday = now.subtract(const Duration(days: 1));
                  await _selectTime(context, targetDate: yesterday);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildCustomDateButton(context),
            ),
          ],
        ),
        if (!isToday) ...[
          const SizedBox(height: 10),
          _buildTimeSelectorCard(context),
        ],
      ],
    );
  }
}
