import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/notification_item.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'GROUP_INVITE':
        return Icons.mail_outline_rounded;
      case 'GROUP_INVITE_ACCEPTED':
        return Icons.person_add_alt_1_rounded;
      case 'GROUP_INVITE_REJECTED':
        return Icons.person_off_rounded;
      case 'GROUP_MEMBER_LEFT':
        return Icons.person_remove_alt_1_rounded;
      case 'GROUP_EXPENSE_ADDED':
        return Icons.receipt_long_rounded;
      case 'GROUP_BILL_ADDED':
        return Icons.event_note_rounded;
      case 'BILL_REMINDER':
        return Icons.alarm_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'GROUP_INVITE':
        return AppTheme.primary;
      case 'GROUP_INVITE_ACCEPTED':
        return AppTheme.secondary;
      case 'GROUP_INVITE_REJECTED':
        return AppTheme.error;
      case 'GROUP_MEMBER_LEFT':
        return AppTheme.tertiary;
      case 'GROUP_EXPENSE_ADDED':
        return const Color(0xFF6366F1);
      case 'GROUP_BILL_ADDED':
        return const Color(0xFF0891B2);
      case 'BILL_REMINDER':
        return const Color(0xFFEA580C);
      default:
        return AppTheme.darkSlateVariant;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationColor(notification.type);
    final iconBgColor = iconColor.withAlpha(25);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppTheme.primaryFixed.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppTheme.outlineVariant.withAlpha(60)
                : AppTheme.primary.withAlpha(40),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(notification.isRead ? 5 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: AppTheme.onBackground,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.darkSlateVariant,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
