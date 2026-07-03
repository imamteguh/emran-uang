import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final DioClient _client = DioClient();

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;
  String? get errorMessage => _errorMessage;

  NotificationProvider() {
    fetchUnreadCount();
  }

  /// Fetch all notifications (paginated)
  Future<void> fetchNotifications({String filter = 'all'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.dio.get(
        '/notifications',
        queryParameters: {
          'filter': filter,
          'limit': '50',
        },
      );

      if (response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        _notifications =
            list.map((n) => NotificationItem.fromJson(n as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = _client.getErrorMessage(e);
      debugPrint('Failed to fetch notifications: $_errorMessage');
    } catch (e) {
      _errorMessage = 'Failed to load notifications';
      debugPrint('Failed to fetch notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch unread count only (lightweight)
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _client.dio.get('/notifications/unread-count');

      if (response.data['success'] == true) {
        _unreadCount = response.data['data']['unreadCount'] as int? ?? 0;
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch unread count: ${_client.getErrorMessage(e)}');
    } catch (e) {
      debugPrint('Failed to fetch unread count: $e');
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    try {
      final response = await _client.dio.post('/notifications/$id/read');

      if (response.data['success'] == true) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = NotificationItem(
            id: _notifications[index].id,
            type: _notifications[index].type,
            title: _notifications[index].title,
            body: _notifications[index].body,
            isRead: true,
            metadata: _notifications[index].metadata,
            createdAt: _notifications[index].createdAt,
          );
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
          notifyListeners();
        }
      }
    } on DioException catch (e) {
      debugPrint('Failed to mark as read: ${_client.getErrorMessage(e)}');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _client.dio.post('/notifications/read-all');

      if (response.data['success'] == true) {
        _notifications = _notifications
            .map((n) => NotificationItem(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  isRead: true,
                  metadata: n.metadata,
                  createdAt: n.createdAt,
                ))
            .toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('Failed to mark all as read: ${_client.getErrorMessage(e)}');
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String id) async {
    try {
      final response = await _client.dio.delete('/notifications/$id');

      if (response.data['success'] == true) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          final wasUnread = !_notifications[index].isRead;
          _notifications.removeAt(index);
          if (wasUnread) {
            _unreadCount = (_unreadCount - 1).clamp(0, 999);
          }
          notifyListeners();
        }
      }
    } on DioException catch (e) {
      debugPrint('Failed to delete notification: ${_client.getErrorMessage(e)}');
    }
  }

  /// Delete all notifications (clear)
  Future<void> clearAllNotifications() async {
    try {
      final response = await _client.dio.delete('/notifications/clear');

      if (response.data['success'] == true) {
        _notifications.clear();
        _unreadCount = 0;
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('Failed to clear notifications: ${_client.getErrorMessage(e)}');
    }
  }
}
