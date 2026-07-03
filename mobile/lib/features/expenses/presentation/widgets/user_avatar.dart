import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = size * 0.38;
    final String fallbackLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('http://') ||
          avatarUrl!.startsWith('https://')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryFixed,
          ),
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultFallback(fallbackLetter, fontSize);
              },
            ),
          ),
        );
      } else if (avatarUrl!.length <= 2) {
        // It's an emoji representation
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryContainer, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            avatarUrl!,
            style: TextStyle(fontSize: size * 0.5),
          ),
        );
      }
    }

    // Default Fallback Initial
    return _buildDefaultFallback(fallbackLetter, fontSize);
  }

  Widget _buildDefaultFallback(String fallbackLetter, double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary,
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackLetter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
