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
    final String fallbackLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryFixed,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: NetworkImage(avatarUrl!),
              fit: BoxFit.cover,
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
            border: Border.all(color: Colors.white, width: 2),
            gradient: const LinearGradient(
              colors: [
                AppTheme.primaryContainer,
                AppTheme.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary,
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
