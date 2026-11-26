import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../config/app_capabilities.dart';
import '../models/subscription_model.dart';

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
  static const String _subscriptionChannelId = 'yotro_subscription_reminders';
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
        final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
        const preferredZones = {
          7 * 3600 * 1000: 'Asia/Jakarta',
          8 * 3600 * 1000: 'Asia/Makassar',
          9 * 3600 * 1000: 'Asia/Jayapura',
        };
        final preferred = preferredZones[offsetMs];
        if (preferred != null) {
          tz.setLocalLocation(tz.getLocation(preferred));
        } else {
          final match = tz.timeZoneDatabase.locations.values.firstWhere(
            (loc) => loc.currentTimeZone.offset == offsetMs,
            orElse: () => tz.getLocation('Asia/Jakarta'),
          );
          tz.setLocalLocation(match);
        }
      } catch (_) {
        // Fallback to local default if timezone database lookup fails
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
    bool skipToday = false,
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
      if (skipToday || scheduledDate.isBefore(now)) {
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

  Future<void> cancelAllDailyReminders({int maxCount = 20}) async {
    if (!_isSupportedMobile) return;
    try {
      await _localNotifications.cancel(id: _dailyReminderId);
      await _localNotifications.cancel(id: 8889);
      for (int i = 0; i < maxCount; i++) {
        await _localNotifications.cancel(id: 8880 + i);
      }
      debugPrint('All daily reminders (8880..${8880 + maxCount - 1}) cancelled');
    } catch (e) {
      debugPrint('Error cancelling all daily reminders: $e');
    }
  }

  static int _subscriptionNotifBaseId(String subId) {
    return 100000 + (subId.hashCode.abs() % 40000000);
  }

  Future<void> scheduleSubscriptionReminders(SubscriptionModel sub) async {
    if (!_isSupportedMobile) return;
    if (!_isInitialized) await initialize();

    final baseId = _subscriptionNotifBaseId(sub.id);
    final hMinus1Id = baseId * 2;
    final dueDayId = baseId * 2 + 1;

    try {
      await _localNotifications.cancel(id: hMinus1Id);
      await _localNotifications.cancel(id: dueDayId);

      if (!sub.reminderEnabled) return;

      final now = tz.TZDateTime.now(tz.local);
      final nextDue = sub.nextDueDate(now);
      final dueAt9am = tz.TZDateTime(
        tz.local,
        nextDue.year,
        nextDue.month,
        nextDue.day,
        9,
        0,
      );
      final hMinus1At9am = dueAt9am.subtract(Duration(days: sub.reminderDaysBefore));

      const androidDetails = AndroidNotificationDetails(
        _subscriptionChannelId,
        'Pengingat Tagihan Rutin',
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
      const details =
          NotificationDetails(android: androidDetails, iOS: darwinDetails);

      if (hMinus1At9am.isAfter(now)) {
        await _localNotifications.zonedSchedule(
          id: hMinus1Id,
          title: 'Besok Jatuh Tempo: ${sub.name}',
          body: 'Jangan lupa siapkan pembayaran tagihan ${sub.name} besok.',
          scheduledDate: hMinus1At9am,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      if (dueAt9am.isAfter(now)) {
        await _localNotifications.zonedSchedule(
          id: dueDayId,
          title: 'Jatuh Tempo Hari Ini: ${sub.name}',
          body: 'Tagihan ${sub.name} jatuh tempo hari ini. Ketuk untuk catat bayar.',
          scheduledDate: dueAt9am,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling subscription reminders: $e');
    }
  }

  Future<void> cancelSubscriptionReminders(String subId) async {
    if (!_isSupportedMobile) return;
    final baseId = _subscriptionNotifBaseId(subId);
    try {
      await _localNotifications.cancel(id: baseId * 2);
      await _localNotifications.cancel(id: baseId * 2 + 1);
    } catch (e) {
      debugPrint('Error cancelling subscription reminders: $e');
    }
  }

  // Notification reader permanently disabled for sideload safety
  Future<bool> isListenerPermissionGranted() async => false;
  Future<bool> requestListenerPermission() async => false;
  void startListening(dynamic onNotificationReceived) {}
  void stopListening() {}
}
