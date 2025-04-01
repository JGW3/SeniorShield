// lib/services/background_service.dart
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/ftc_alert.dart';
import 'ftc_scraper_service.dart';
import 'cache_service.dart';

class BackgroundService {
  static const int taskId = 0;
  static const String taskName = 'checkFtcAlerts';
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _initNotifications();
    await AndroidAlarmManager.initialize();

    // Schedule daily alert check
    await scheduleDaily();
  }

  static Future<void> scheduleDaily({TimeOfDay? time}) async {
    final scheduledTime = time ?? const TimeOfDay(hour: 9, minute: 0);

    final now = DateTime.now();
    final scheduledDateTime = DateTime(
        now.year, now.month, now.day, scheduledTime.hour, scheduledTime.minute);

    // Calculate time for next occurrence
    DateTime nextRun = scheduledDateTime;
    if (nextRun.isBefore(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }

    await AndroidAlarmManager.periodic(
      const Duration(hours: 24),
      taskId,
      checkForFtcAlerts,
      startAt: nextRun,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    // Fix: Format time directly without using MaterialLocalizations
    final hourString = scheduledTime.hour.toString();
    final minuteString = scheduledTime.minute.toString().padLeft(2, '0');
    debugPrint('Scheduled daily FTC alert check at $hourString:$minuteString');
  }

  static Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  static Future<void> showNotification(int newAlertsCount) async {
    const androidDetails = AndroidNotificationDetails(
      'ftc_alerts_channel',
      'FTC Consumer Alerts',
      channelDescription: 'Notifications for new FTC consumer alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'New FTC Consumer Alerts',
      'There ${newAlertsCount == 1 ? 'is' : 'are'} $newAlertsCount new FTC consumer alert${newAlertsCount == 1 ? '' : 's'}.',
      details,
    );
  }
}

@pragma('vm:entry-point')
void checkForFtcAlerts() async {
  // Register a port for isolate communication
  final port = ReceivePort();
  IsolateNameServer.registerPortWithName(
      port.sendPort,
      'background_ftc_alerts'
  );

  try {
    debugPrint('Running background task: checking FTC alerts');

    final service = FtcScraperService();
    final cacheService = CacheService();

    final shouldFetch = await cacheService.shouldFetchFreshData();
    if (!shouldFetch) {
      debugPrint('No need to fetch fresh data yet');
      return;
    }

    // Get cached alerts
    final cachedAlerts = await cacheService.getCachedAlerts();
    final cachedLinks = cachedAlerts.map((a) => a.link).toSet();

    // Fetch new alerts
    final freshAlerts = await service.fetchAlerts();

    // Find new alerts (links not in cached alerts)
    final newAlerts = freshAlerts
        .where((alert) => !cachedLinks.contains(alert.link))
        .toList();

    // Cache fresh alerts
    await cacheService.cacheAlerts(freshAlerts);

    // Show notification if there are new alerts
    if (newAlerts.isNotEmpty) {
      await BackgroundService.showNotification(newAlerts.length);
    }
  } catch (e) {
    debugPrint('Error in background task: $e');
  } finally {
    IsolateNameServer.removePortNameMapping('background_ftc_alerts');
  }
}