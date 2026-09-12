import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';

class AuthCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const AuthCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.maxWidth = 460.0,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final double effectiveWidth =
        responsive.isTablet || responsive.isDesktop ? maxWidth : double.infinity;

    return Center(
      child: SizedBox(
        width: effectiveWidth,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
