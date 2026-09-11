import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';

class TransactionFilterCriteria {
  final DateTime startDate;
  final DateTime endDate;
  final ExpenseType? type;
  final String? categoryId;

  const TransactionFilterCriteria({
    required this.startDate,
    required this.endDate,
    this.type,
    this.categoryId,
  });

  int get dayCount {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return e.difference(s).inDays + 1;
  }

  TransactionFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
  }) {
    return TransactionFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class TransactionCalendarFilterSheet extends StatefulWidget {
  final TransactionFilterCriteria initialCriteria;
  final List<ExpenseCategory> categories;
  final ValueChanged<TransactionFilterCriteria> onApply;

  const TransactionCalendarFilterSheet({
    super.key,
    required this.initialCriteria,
    required this.categories,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionFilterCriteria initialCriteria,
    required List<ExpenseCategory> categories,
    required ValueChanged<TransactionFilterCriteria> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionCalendarFilterSheet(
        initialCriteria: initialCriteria,
        categories: categories,
        onApply: onApply,
      ),
    );
  }

  @override
  State<TransactionCalendarFilterSheet> createState() =>
      _TransactionCalendarFilterSheetState();
}

class _TransactionCalendarFilterSheetState
    extends State<TransactionCalendarFilterSheet> {
  late DateTime _startDate;
  late DateTime _endDate;

  late DateTime _displayedMonth;
  String? _errorMessage;

  static const int maxRangeDays = 31;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialCriteria.startDate.year,
      widget.initialCriteria.startDate.month,
      widget.initialCriteria.startDate.day,
    );
    _endDate = DateTime(
      widget.initialCriteria.endDate.year,
      widget.initialCriteria.endDate.month,
      widget.initialCriteria.endDate.day,
    );

    _displayedMonth = DateTime(_endDate.year, _endDate.month, 1);
  }

  int get _selectedRangeCount {
    return _endDate.difference(_startDate).inDays + 1;
  }

  void _onPresetSelected(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _errorMessage = null;
      switch (preset) {
        case 'today':
          _startDate = today;
          _endDate = today;
          break;
        case '7days':
          _startDate = today.subtract(const Duration(days: 6));
          _endDate = today;
          break;
        case '30days':
          _startDate = today.subtract(const Duration(days: 29));
          _endDate = today;
          break;
        case 'thisMonth':
          _startDate = DateTime(today.year, today.month, 1);
          _endDate = today;
          break;
      }
      _displayedMonth = DateTime(_endDate.year, _endDate.month, 1);
    });
  }

  void _onDateCellTapped(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Cannot pick future date
    if (date.isAfter(today)) return;

    setState(() {
      _errorMessage = null;

      // If both dates were already selected (range set), restart selection with clicked date
      if (_startDate != _endDate) {
        _startDate = date;
        _endDate = date;
      } else {
        // Only one date selected
        if (date.isBefore(_startDate)) {
          // If clicked date is before start date, it becomes new start date
          _startDate = date;
        } else {
          // User clicked end date
          final diffDays = date.difference(_startDate).inDays + 1;
          if (diffDays > maxRangeDays) {
            // Exceeds 31 days limit -> Clamp to 31 days & alert
            _endDate = _startDate.add(const Duration(days: maxRangeDays - 1));
            _errorMessage =
                'Rentang maksimal 31 hari. Tanggal otomatis dibatasi.';
          } else {
            _endDate = date;
          }
        }
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    if (_displayedMonth.isBefore(currentMonth)) {
      setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
      });
    }
  }

  void _resetFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _startDate = today.subtract(const Duration(days: 30));
      _endDate = today;
      _errorMessage = null;
      _displayedMonth = DateTime(today.year, today.month, 1);
    });
  }

  void _applyFilter() {
    if (_selectedRangeCount > maxRangeDays) {
      setState(() {
        _errorMessage = 'Rentang tanggal tidak boleh melebihi 31 hari';
      });
      return;
    }

    widget.onApply(
      TransactionFilterCriteria(
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final canGoNextMonth = _displayedMonth.isBefore(currentMonth);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Tanggal Aktivitas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        splashRadius: 20,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Max 31 Days Notification Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Soft light blue
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rentang tanggal maksimal 31 hari untuk menampilkan riwayat aktivitas.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Presets
                    Text(
                      'Pilihan Cepat Periode',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('Hari Ini', 'today'),
                          const SizedBox(width: 8),
                          _buildPresetChip('7 Hari', '7days'),
                          const SizedBox(width: 8),
                          _buildPresetChip('30 Hari', '30days'),
                          const SizedBox(width: 8),
                          _buildPresetChip('Bulan Ini', 'thisMonth'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Calendar Range Selector Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Tanggal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedRangeCount > maxRangeDays
                                ? const Color(0xFFFEE2E2)
                                : AppTheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_selectedRangeCount Hari dipilih',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _selectedRangeCount > maxRangeDays
                                  ? const Color(0xFFDC2626)
                                  : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Selected Range Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DARI TANGGAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy', 'id_ID')
                                      .format(_startDate),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'SAMPAI TANGGAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy', 'id_ID')
                                      .format(_endDate),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Calendar Widget Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Month Navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
                                onPressed: _previousMonth,
                                splashRadius: 20,
                              ),
                              Text(
                                DateFormat('MMMM yyyy', 'id_ID')
                                    .format(_displayedMonth),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
                                onPressed: canGoNextMonth ? _nextMonth : null,
                                splashRadius: 20,
                                color: canGoNextMonth
                                    ? AppTheme.darkSlate
                                    : const Color(0xFFCBD5E1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Days of Week Header (Min, Sen, Sel, Rab, Kam, Jum, Sab)
                          Row(
                            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                                .map((day) => Expanded(
                                      child: Center(
                                        child: Text(
                                          day,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 8),

                          // Calendar Days Grid
                          _buildCalendarMonthGrid(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _resetFilter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Atur Ulang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Tampilkan ($_selectedRangeCount Hari)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildPresetChip(String label, String presetKey) {
    return ActionChip(
      onPressed: () => _onPresetSelected(presetKey),
      backgroundColor: const Color(0xFFF1F5F9),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkSlate,
        ),
      ),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildCalendarMonthGrid() {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Widget> dayWidgets = [];

    // Empty lead slots before start weekday
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(year, month, day);
      final isFuture = cellDate.isAfter(today);

      final isStart = cellDate == _startDate;
      final isEnd = cellDate == _endDate;
      final isInRange = cellDate.isAfter(_startDate) && cellDate.isBefore(_endDate);
      final isSelectedSingle = isStart && isEnd;

      Color? bgColor;
      Color textColor = AppTheme.darkSlate;
      BorderRadius? cellRadius;

      if (isFuture) {
        textColor = const Color(0xFFCBD5E1);
      } else if (isSelectedSingle) {
        bgColor = AppTheme.primary;
        textColor = Colors.white;
        cellRadius = BorderRadius.circular(20);
      } else if (isStart) {
        bgColor = AppTheme.primary;
        textColor = Colors.white;
        cellRadius = const BorderRadius.horizontal(left: Radius.circular(20));
      } else if (isEnd) {
        bgColor = AppTheme.primary;
        textColor = Colors.white;
        cellRadius = const BorderRadius.horizontal(right: Radius.circular(20));
      } else if (isInRange) {
        bgColor = const Color(0xFFDBEAFE); // Light blue range ribbon
        textColor = const Color(0xFF1E3A8A);
      }

      dayWidgets.add(
        InkWell(
          onTap: isFuture ? null : () => _onDateCellTapped(cellDate),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: cellRadius,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: (isStart || isEnd || cellDate == today)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 0,
      children: dayWidgets,
    );
  }
}
