import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? helperText;
  final bool autofocus;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.helperText,
    this.autofocus = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.enabled ? AppTheme.darkSlate : AppTheme.darkSlateVariant,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            filled: true,
            fillColor: widget.enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(
              widget.prefixIcon,
              size: 20,
              color: widget.enabled ? AppTheme.darkSlateVariant : const Color(0xFF94A3B8),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.darkSlateVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppTheme.error, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
