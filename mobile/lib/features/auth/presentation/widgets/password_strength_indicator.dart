import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final String? confirmPassword;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.confirmPassword,
  });

  double _calculateStrength(String val) {
    if (val.isEmpty) return 0.0;
    double strength = 0.0;
    if (val.length >= 8) strength += 0.35;
    if (val.length >= 12) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(val) && RegExp(r'[a-z]').hasMatch(val)) {
      strength += 0.25;
    }
    if (RegExp(r'[0-9]').hasMatch(val)) strength += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(val)) strength += 0.10;
    return strength.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength == 0.0) return const Color(0xFFCBD5E1);
    if (strength < 0.4) return AppTheme.error;
    if (strength < 0.7) return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  String _getStrengthLabel(double strength) {
    if (strength == 0.0) return 'Belum Diisi';
    if (strength < 0.4) return 'Kata Sandi Lemah';
    if (strength < 0.7) return 'Kata Sandi Sedang';
    if (strength < 0.9) return 'Kata Sandi Kuat';
    return 'Kata Sandi Sangat Kuat';
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final color = _getStrengthColor(strength);
    final label = _getStrengthLabel(strength);

    final hasMinLength = password.length >= 8;
    final hasUpperLower =
        RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password);
    final hasNumberOrSymbol =
        RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
    final bool passwordsMatch = confirmPassword != null &&
        confirmPassword!.isNotEmpty &&
        password == confirmPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kekuatan Kata Sandi:',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: AppTheme.darkSlateVariant,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildCheckChip('Min. 8 Karakter', hasMinLength),
            _buildCheckChip('Huruf Besar & Kecil', hasUpperLower),
            _buildCheckChip('Angka / Simbol', hasNumberOrSymbol),
            if (confirmPassword != null)
              _buildCheckChip('Sandi Cocok', passwordsMatch),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckChip(String label, bool passed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: passed ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: passed ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: passed ? const Color(0xFF15803D) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
