import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notifications/notifications.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<NotificationBloc>()
          .add(const NotificationFetchNotificationsRequested());
    });
  }

  Future<void> _handleClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Notifications',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete all notifications?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Clear All',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<NotificationBloc>().add(const NotificationClearAllRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationBloc>().state;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.onBackground,
          ),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (provider.notifications.isNotEmpty)
            IconButton(
              onPressed: _handleClearAll,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: AppTheme.error,
              ),
              tooltip: 'Clear all',
            ),
          if (provider.hasUnread)
            TextButton.icon(
              onPressed: () => context
                  .read<NotificationBloc>()
                  .add(const NotificationMarkAllAsReadRequested()),
              icon: const Icon(
                Icons.done_all_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
              label: Text(
                'Read all',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<NotificationBloc>()
              .add(const NotificationFetchNotificationsRequested());
          context
              .read<NotificationBloc>()
              .add(const NotificationFetchUnreadCountRequested());
        },
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(NotificationState provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (provider.notifications.isEmpty) {
      return const NotificationEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          onDismissed: (_) {
            context
                .read<NotificationBloc>()
                .add(NotificationDeleteRequested(notification.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification deleted'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: NotificationCard(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                context
                    .read<NotificationBloc>()
                    .add(NotificationMarkAsReadRequested(notification.id));
              }
            },
          ),
        );
      },
    );
  }
}
