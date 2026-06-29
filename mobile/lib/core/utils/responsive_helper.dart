import 'package:flutter/material.dart';

/// A utility class to help make UI elements responsive.
/// Defines breakpoints for Mobile, Tablet, and Desktop, and provides
/// methods to scale fonts, padding, and grids dynamically.
class ResponsiveHelper {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  final BuildContext context;
  late MediaQueryData _mediaQueryData;
  late double screenWidth;
  late double screenHeight;

  ResponsiveHelper(this.context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }

  bool get isMobile => screenWidth < mobileBreakpoint;
  bool get isTablet => screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;
  bool get isDesktop => screenWidth >= tabletBreakpoint;

  /// Returns a scaled value based on the screen width.
  /// Ideal for scaling padding, margins, or card sizes.
  double scale(double value, {double tabletMultiplier = 1.3, double desktopMultiplier = 1.6}) {
    if (isTablet) {
      return value * tabletMultiplier;
    } else if (isDesktop) {
      return value * desktopMultiplier;
    }
    return value; // base mobile size
  }

  /// Responsive padding helper
  EdgeInsets get screenPadding {
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    } else if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Responsive cross axis count for GridViews
  int get gridCrossAxisCount {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2; // mobile default
  }

  /// Scale font sizes dynamically with a cap to prevent overly massive text on large screens
  double scaleFont(double baseSize) {
    if (isDesktop) {
      return baseSize * 1.4;
    } else if (isTablet) {
      return baseSize * 1.25;
    }
    return baseSize;
  }
}
