import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';

class AiChatSuggestionChips extends StatelessWidget {
  final ValueChanged<String> onSelectSuggestion;

  const AiChatSuggestionChips({
    super.key,
    required this.onSelectSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      '🍔 Makan siang 25k',
      '☕ Kopi 15k jam 10',
      '⛽ Bensin 50rb',
      '🛒 Belanja 120k jam 14.30',
      '🍜 Mie ayam 18k kemarin jam 7 malam',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final cleanText =
                        suggestion.replaceFirst(RegExp(r'^[^\w]+\s*'), '');
                    onSelectSuggestion(cleanText);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class AiChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAiTyping;
  final VoidCallback onSend;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isAiTyping,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withAlpha(128),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 1,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            color: AppTheme.onBackground,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Tulis pengeluaran... (cth: makan siang 25k)',
                            hintStyle: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              color: AppTheme.outline,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            filled: false,
                          ),
                          onSubmitted: (_) => onSend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                child: Material(
                  color: isAiTyping
                      ? AppTheme.outline.withAlpha(51)
                      : AppTheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: isAiTyping ? null : onSend,
                    borderRadius: BorderRadius.circular(24),
                    child: Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: isAiTyping ? AppTheme.outline : Colors.white,
                        size: 22,
                      ),
                    ),
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

class AiChatEmptyState extends StatelessWidget {
  final ResponsiveHelper responsive;

  const AiChatEmptyState({
    super.key,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'AI Expense Assistant',
              style: AppTheme.headlineSm.copyWith(
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketik pesan untuk menyimpan transaksi',
              style: AppTheme.bodyMd.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
