import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';

class AiChatTypingIndicator extends StatefulWidget {
  final ResponsiveHelper responsive;

  const AiChatTypingIndicator({
    super.key,
    required this.responsive,
  });

  @override
  State<AiChatTypingIndicator> createState() => _AiChatTypingIndicatorState();
}

class _AiChatTypingIndicatorState extends State<AiChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _typingController;
  late Animation<double> _typingDot1;
  late Animation<double> _typingDot2;
  late Animation<double> _typingDot3;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _typingDot1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );
    _typingDot2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );
    _typingDot3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> animation) {
    return Transform.translate(
      offset: Offset(0, -4 * animation.value),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.primary
              .withAlpha((100 + 155 * animation.value).toInt()),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: AppTheme.outlineVariant.withAlpha(128),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(_typingDot1),
                    const SizedBox(width: 4),
                    _buildDot(_typingDot2),
                    const SizedBox(width: 4),
                    _buildDot(_typingDot3),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
