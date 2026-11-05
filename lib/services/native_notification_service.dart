import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../config/app_capabilities.dart';

typedef NotificationReceivedCallback = void Function({
  required String sourceApp,
  required String message,
  required String packageName,
});

class NativeNotificationService {
  NativeNotificationService._();
  static final NativeNotificationService instance =
      NativeNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  StreamSubscription? _subscription;

  static const String _reminderChannelId = 'yotro_daily_reminder';
  static const String _detectedChannelId = 'yotro_detected_tx';
  static const int _dailyReminderId = 8888;

  bool get _isSupportedMobile {
    if (kIsWeb) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (!_isSupportedMobile || _isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final location = tz.getLocation('Asia/Jakarta');
        tz.setLocalLocation(location);
      } catch (_) {
        // Fallback to local default if timezone database lacks Asia/Jakarta
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings =
          InitializationSettings(android: androidInit, iOS: darwinInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _reminderChannelId,
            'Pengingat Transaksi Harian',
            description:
                'Notifikasi pengingat harian jika belum mencatat pengeluaran/pemasukan',
            importance: Importance.max,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _detectedChannelId,
            'Transaksi Terdeteksi',
            description:
                'Notifikasi otomatis saat transaksi baru terdeteksi dari bank/e-wallet',
            importance: Importance.max,
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }
  }

  Future<bool> requestPostNotificationPermission() async {
    if (!_isSupportedMobile) return false;
    try {
      if (Platform.isAndroid) {
        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting post notification permission: $e');
      return false;
    }
  }

  Future<void> showPushNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isReminder = false,
  }) async {
    if (!_isSupportedMobile) return;
    if (!_isInitialized) await initialize();

    try {
      final channelId = isReminder ? _reminderChannelId : _detectedChannelId;
      final channelName =
          isReminder ? 'Pengingat Transaksi Harian' : 'Transaksi Terdeteksi';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details =
          NotificationDetails(android: androidDetails, iOS: darwinDetails);

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing push notification: $e');
    }
  }

  Future<void> scheduleDailyReminder({
    int id = _dailyReminderId,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_isSupportedMobile) return;
    if (!_isInitialized) await initialize();

    try {
      await _localNotifications.cancel(id: id);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _reminderChannelId,
        'Pengingat Transaksi Harian',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details =
          NotificationDetails(android: androidDetails, iOS: darwinDetails);

      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
          'Daily reminder #$id scheduled at $hour:$minute (first: $scheduledDate)');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  Future<void> cancelDailyReminder({int id = _dailyReminderId}) async {
    if (!_isSupportedMobile) return;
    try {
      await _localNotifications.cancel(id: id);
      debugPrint('Daily reminder #$id cancelled');
    } catch (e) {
      debugPrint('Error cancelling daily reminder: $e');
    }
  }

  // Notification reader permanently disabled for sideload safety
  Future<bool> isListenerPermissionGranted() async => false;
  Future<bool> requestListenerPermission() async => false;
  void startListening(dynamic onNotificationReceived) {}
  void stopListening() {}
}
