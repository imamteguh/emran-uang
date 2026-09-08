import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

/// Image preview widget displaying the cropped receipt with floating status badge.
class OcrImagePreview extends StatelessWidget {
  final File imageFile;
  final bool isProcessing;
  final bool hasResult;

  const OcrImagePreview({
    super.key,
    required this.imageFile,
    required this.isProcessing,
    required this.hasResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: double.infinity,
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                imageFile,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 220,
                    color: const Color(0xFFE2E8F0),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(60),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Status badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isProcessing
                        ? AppTheme.primary.withAlpha(220)
                        : hasResult
                            ? AppTheme.secondary.withAlpha(220)
                            : Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isProcessing)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          hasResult
                              ? Icons.check_circle_rounded
                              : Icons.image_rounded,
                          size: 14,
                          color: hasResult
                              ? Colors.white
                              : AppTheme.darkSlateVariant,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        isProcessing
                            ? 'Scanning...'
                            : hasResult
                                ? 'Scanned'
                                : 'Receipt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isProcessing || hasResult
                              ? Colors.white
                              : AppTheme.darkSlateVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
