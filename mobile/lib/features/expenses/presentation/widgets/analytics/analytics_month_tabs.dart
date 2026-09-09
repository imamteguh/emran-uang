import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class AnalyticsMonthTabs extends StatelessWidget {
  final ScrollController controller;
  final List<dynamic> monthsList;
  final int activeFilterIndex;
  final ValueChanged<int> onTabSelected;
  final String Function(String) monthYearFormatter;

  const AnalyticsMonthTabs({
    super.key,
    required this.controller,
    required this.monthsList,
    required this.activeFilterIndex,
    required this.onTabSelected,
    required this.monthYearFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: List.generate(monthsList.length, (i) {
            // Reverse index so the oldest month is on the left and the newest is on the right
            final index = monthsList.length - 1 - i;
            final monthData = monthsList[index] as Map<String, dynamic>;
            final label = monthYearFormatter(monthData['month'] as String);
            final isSelected = activeFilterIndex == index;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.darkSlateVariant,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
