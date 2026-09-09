class BillsDateFormatter {
  static const List<String> _monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatMonthYear(DateTime date) {
    return '${_monthsFull[date.month - 1]} ${date.year}';
  }

  static String formatDayMonth(DateTime date) {
    return '${date.day} ${_monthsShort[date.month - 1]}';
  }
}
