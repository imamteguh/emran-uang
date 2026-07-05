import 'notification_item.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final NotificationStatus status;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.status = NotificationStatus.initial,
  });

  bool get hasUnread => unreadCount > 0;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    NotificationStatus? status,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      status: status ?? this.status,
    );
  }
}
