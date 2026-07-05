abstract class NotificationEvent {
  const NotificationEvent();
}

class NotificationFetchNotificationsRequested extends NotificationEvent {
  final String filter;

  const NotificationFetchNotificationsRequested({this.filter = 'all'});
}

class NotificationFetchUnreadCountRequested extends NotificationEvent {
  const NotificationFetchUnreadCountRequested();
}

class NotificationMarkAsReadRequested extends NotificationEvent {
  final String id;

  const NotificationMarkAsReadRequested(this.id);
}

class NotificationMarkAllAsReadRequested extends NotificationEvent {
  const NotificationMarkAllAsReadRequested();
}

class NotificationDeleteRequested extends NotificationEvent {
  final String id;

  const NotificationDeleteRequested(this.id);
}

class NotificationClearAllRequested extends NotificationEvent {
  const NotificationClearAllRequested();
}
