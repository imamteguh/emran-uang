import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class AuthSocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const AuthSocialButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.darkSlate,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google.png',
                    height: 22,
                    width: 22,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
