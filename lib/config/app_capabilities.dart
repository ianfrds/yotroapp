import 'package:flutter/foundation.dart';

/// Build-time capability switches for features that require sensitive Android
/// permissions. Public/sideload-safe builds keep these disabled by default.
class AppCapabilities {
  const AppCapabilities._();

  static const bool _notificationReaderBuildEnabled = bool.fromEnvironment(
    'YOTRO_NOTIFICATION_READER',
    defaultValue: false,
  );

  static bool get notificationReaderEnabled {
    return _notificationReaderBuildEnabled &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android;
  }
}
