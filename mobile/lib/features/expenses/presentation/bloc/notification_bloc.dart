import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'notification_item.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final DioClient _client = DioClient();

  NotificationBloc() : super(const NotificationState()) {
    on<NotificationFetchNotificationsRequested>(_onFetchNotificationsRequested);
    on<NotificationFetchUnreadCountRequested>(_onFetchUnreadCountRequested);
    on<NotificationMarkAsReadRequested>(_onMarkAsReadRequested);
    on<NotificationMarkAllAsReadRequested>(_onMarkAllAsReadRequested);
    on<NotificationDeleteRequested>(_onDeleteRequested);
    on<NotificationClearAllRequested>(_onClearAllRequested);
  }

  Future<void> _onFetchNotificationsRequested(
    NotificationFetchNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: NotificationStatus.loading,
    ));

    try {
      final response = await _client.dio.get(
        '/notifications',
        queryParameters: {
          'filter': event.filter,
          'limit': '50',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        final notifications = list
            .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
            .toList();

        emit(state.copyWith(
          notifications: notifications,
          isLoading: false,
          status: NotificationStatus.success,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          status: NotificationStatus.failure,
        ));
      }
    } on DioException catch (e) {
      final errMsg = _client.getErrorMessage(e);
      debugPrint('Failed to fetch notifications: $errMsg');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: errMsg,
        status: NotificationStatus.failure,
      ));
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications',
        status: NotificationStatus.failure,
      ));
    }
  }

  Future<void> _onFetchUnreadCountRequested(
    NotificationFetchUnreadCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await _client.dio.get('/notifications/unread-count');

      if (response.data != null && response.data['success'] == true) {
        final count = response.data['data']['unreadCount'] as int? ?? 0;
        emit(state.copyWith(unreadCount: count));
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch unread count: ${_client.getErrorMessage(e)}');
    } catch (e) {
      debugPrint('Failed to fetch unread count: $e');
    }
  }

  Future<void> _onMarkAsReadRequested(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await _client.dio.post('/notifications/${event.id}/read');

      if (response.data != null && response.data['success'] == true) {
        final index = state.notifications.indexWhere((n) => n.id == event.id);
        if (index != -1 && !state.notifications[index].isRead) {
          final updatedNotifications = List<NotificationItem>.from(state.notifications);
          final currentItem = updatedNotifications[index];
          updatedNotifications[index] = NotificationItem(
            id: currentItem.id,
            type: currentItem.type,
            title: currentItem.title,
            body: currentItem.body,
            isRead: true,
            metadata: currentItem.metadata,
            createdAt: currentItem.createdAt,
          );

          emit(state.copyWith(
            notifications: updatedNotifications,
            unreadCount: (state.unreadCount - 1).clamp(0, 999),
          ));
        }
      }
    } on DioException catch (e) {
      debugPrint('Failed to mark as read: ${_client.getErrorMessage(e)}');
    }
  }

  Future<void> _onMarkAllAsReadRequested(
    NotificationMarkAllAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await _client.dio.post('/notifications/read-all');

      if (response.data != null && response.data['success'] == true) {
        final updatedNotifications = state.notifications
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

        emit(state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        ));
      }
    } on DioException catch (e) {
      debugPrint('Failed to mark all as read: ${_client.getErrorMessage(e)}');
    }
  }

  Future<void> _onDeleteRequested(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await _client.dio.delete('/notifications/${event.id}');

      if (response.data != null && response.data['success'] == true) {
        final index = state.notifications.indexWhere((n) => n.id == event.id);
        if (index != -1) {
          final wasUnread = !state.notifications[index].isRead;
          final updatedNotifications = List<NotificationItem>.from(state.notifications)
            ..removeAt(index);

          emit(state.copyWith(
            notifications: updatedNotifications,
            unreadCount: wasUnread ? (state.unreadCount - 1).clamp(0, 999) : state.unreadCount,
          ));
        }
      }
    } on DioException catch (e) {
      debugPrint('Failed to delete notification: ${_client.getErrorMessage(e)}');
    }
  }

  Future<void> _onClearAllRequested(
    NotificationClearAllRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await _client.dio.delete('/notifications/clear');

      if (response.data != null && response.data['success'] == true) {
        emit(state.copyWith(
          notifications: const [],
          unreadCount: 0,
        ));
      }
    } on DioException catch (e) {
      debugPrint('Failed to clear notifications: ${_client.getErrorMessage(e)}');
    }
  }
}
