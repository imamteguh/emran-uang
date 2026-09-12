import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';

class AuthBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBrandLogo;

  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBrandLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBrandLogo) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(70),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'WalletShare',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(24),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: responsive.scaleFont(26),
            fontWeight: FontWeight.w800,
            color: AppTheme.darkSlate,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: responsive.scaleFont(14),
            color: AppTheme.darkSlateVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
