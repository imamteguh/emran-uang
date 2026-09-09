import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';

class ActivityEmptyState extends StatelessWidget {
  final DateTime selectedDate;

  const ActivityEmptyState({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final isToday =
        selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;
    final dateStr = isToday
        ? 'today'
        : DateFormat('dd MMM').format(selectedDate);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40),
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'No activity recorded on $dateStr',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All clear! No expenses noted for this day.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
