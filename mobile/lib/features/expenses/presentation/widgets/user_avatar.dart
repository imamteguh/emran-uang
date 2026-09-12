import 'dart:convert';
import 'dart:io';
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
        displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'U';

    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      final cleanUrl = avatarUrl!.trim();

      // 1. Network image
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryFixed,
          ),
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              cleanUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _buildDefaultFallback(fallbackLetter, fontSize),
            ),
          ),
        );
      }

      // 2. Base64 data image
      if (cleanUrl.startsWith('data:image')) {
        try {
          final base64Str = cleanUrl.split(',').last;
          final bytes = base64Decode(base64Str);
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryFixed,
            ),
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _buildDefaultFallback(fallbackLetter, fontSize),
              ),
            ),
          );
        } catch (_) {}
      }

      // 3. Local file path
      if (cleanUrl.startsWith('/') ||
          cleanUrl.startsWith('file:') ||
          cleanUrl.contains(':\\') ||
          cleanUrl.contains(':/')) {
        try {
          final filePath = cleanUrl.replaceFirst('file://', '');
          final file = File(filePath);
          if (file.existsSync()) {
            return Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryFixed,
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _buildDefaultFallback(fallbackLetter, fontSize),
                ),
              ),
            );
          }
        } catch (_) {}
      }

      // 4. Emoji representation (check runes length to support complex emojis)
      if (cleanUrl.runes.length <= 4 && !cleanUrl.contains('.')) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
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
            cleanUrl,
            style: TextStyle(fontSize: size * 0.48),
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
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
