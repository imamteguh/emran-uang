import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';

class CurrencyPickerBottomSheet extends StatelessWidget {
  final DashboardBloc dashboardBloc;
  final String currentCurrency;

  const CurrencyPickerBottomSheet({
    super.key,
    required this.dashboardBloc,
    required this.currentCurrency,
  });

  static Future<void> show(BuildContext context, DashboardBloc bloc, String current) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencyPickerBottomSheet(
        dashboardBloc: bloc,
        currentCurrency: current,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> currencies = [
      {'code': 'IDR', 'name': 'Rupiah (IDR)', 'symbol': 'Rp'},
      {'code': 'USD', 'name': 'US Dollar (USD)', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro (EUR)', 'symbol': '€'},
      {'code': 'SGD', 'name': 'Singapore Dollar (SGD)', 'symbol': 'S\$'},
      {'code': 'JPY', 'name': 'Japanese Yen (JPY)', 'symbol': '¥'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Currency',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Change the currency of your active wallet.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currencies.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final curr = currencies[index];
              final isSelected = curr['code'] == currentCurrency;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  curr['name']!,
                  style: GoogleFonts.beVietnamPro(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primary : AppTheme.darkSlate,
                  ),
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withAlpha(25)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    curr['symbol']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.darkSlateVariant,
                    ),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.primary,
                      )
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  final completer = Completer<bool>();
                  dashboardBloc.add(
                    DashboardUpdateWalletCurrencyRequested(
                      curr['code']!,
                      completer,
                    ),
                  );
                  final success = await completer.future;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Currency successfully changed to ${curr['code']}!'
                              : 'Failed to change currency.',
                        ),
                        backgroundColor:
                            success ? Colors.green : AppTheme.error,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class ThemePickerBottomSheet extends StatelessWidget {
  final String currentTheme;
  final ValueChanged<String> onThemeSelected;

  const ThemePickerBottomSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
  });

  static Future<void> show(
    BuildContext context,
    String current,
    ValueChanged<String> onSelected,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemePickerBottomSheet(
        currentTheme: current,
        onThemeSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> themes = [
      {'id': 'Light', 'name': 'Light', 'icon': Icons.light_mode},
      {'id': 'Dark', 'name': 'Dark', 'icon': Icons.dark_mode},
      {'id': 'System', 'name': 'System Default', 'icon': Icons.brightness_auto},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Theme',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your preferred app theme.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: themes.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = theme['id'] == currentTheme;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  theme['name'],
                  style: GoogleFonts.beVietnamPro(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primary : AppTheme.darkSlate,
                  ),
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withAlpha(25)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    theme['icon'],
                    size: 18,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.darkSlateVariant,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onThemeSelected(theme['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Theme changed to ${theme['name']}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class NotificationPickerBottomSheet extends StatefulWidget {
  final bool initialPush;
  final bool initialEmail;
  final bool initialMonthly;
  final void Function(bool push, bool email, bool monthly) onChanged;

  const NotificationPickerBottomSheet({
    super.key,
    required this.initialPush,
    required this.initialEmail,
    required this.initialMonthly,
    required this.onChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required bool push,
    required bool email,
    required bool monthly,
    required void Function(bool push, bool email, bool monthly) onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationPickerBottomSheet(
        initialPush: push,
        initialEmail: email,
        initialMonthly: monthly,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<NotificationPickerBottomSheet> createState() =>
      _NotificationPickerBottomSheetState();
}

class _NotificationPickerBottomSheetState
    extends State<NotificationPickerBottomSheet> {
  late bool _push;
  late bool _email;
  late bool _monthly;

  @override
  void initState() {
    super.initState();
    _push = widget.initialPush;
    _email = widget.initialEmail;
    _monthly = widget.initialMonthly;
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onToggle,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Notifications',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your notification preferences.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 20),
          _buildSwitchItem(
            title: 'Push Notifications',
            subtitle: 'Receive alerts on your device',
            value: _push,
            onToggle: (val) {
              setState(() => _push = val);
              widget.onChanged(_push, _email, _monthly);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildSwitchItem(
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: _email,
            onToggle: (val) {
              setState(() => _email = val);
              widget.onChanged(_push, _email, _monthly);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildSwitchItem(
            title: 'Monthly Reports',
            subtitle: 'Receive monthly financial summaries',
            value: _monthly,
            onToggle: (val) {
              setState(() => _monthly = val);
              widget.onChanged(_push, _email, _monthly);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
