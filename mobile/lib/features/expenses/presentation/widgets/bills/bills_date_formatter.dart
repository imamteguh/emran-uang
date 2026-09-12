class BillsDateFormatter {
  static const List<String> _monthsFull = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];


  static String formatMonthYear(DateTime date) {
    return '${_monthsFull[date.month - 1]} ${date.year}';
  }

  static String formatDayMonth(DateTime date) {
    return '${date.day} ${_monthsShort[date.month - 1]}';
  }
}
