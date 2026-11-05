import 'package:flutter/foundation.dart';

/// Build-time capability switches for features that require sensitive Android
/// permissions. Public/sideload-safe builds keep these disabled by default.
class AppCapabilities {
  const AppCapabilities._();

  static const bool _notificationReaderBuildEnabled = false;

  static bool get notificationReaderEnabled => false;
}
