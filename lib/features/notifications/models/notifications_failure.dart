sealed class NotificationsFailure implements Exception {
  const NotificationsFailure();
}

class NotificationsValidationFailure extends NotificationsFailure {
  const NotificationsValidationFailure();
}

class NotificationsServiceUnavailableFailure extends NotificationsFailure {
  const NotificationsServiceUnavailableFailure();
}
