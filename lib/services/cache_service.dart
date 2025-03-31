// lib/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ftc_alert.dart';

class CacheService {
  static const String _alertsCacheKey = 'ftc_alerts_cache';
  static const String _lastFetchTimeKey = 'ftc_alerts_last_fetch';
  static const int _cacheDurationHours = 24;

  Future<void> cacheAlerts(List<FtcAlert> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = alerts.map((alert) => alert.toJson()).toList();
      await prefs.setString(_alertsCacheKey, jsonEncode(alertsJson));
      await prefs.setString(_lastFetchTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching alerts: $e');
    }
  }

  Future<List<FtcAlert>> getCachedAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsString = prefs.getString(_alertsCacheKey);
      if (alertsString == null) return [];

      final alertsJson = jsonDecode(alertsString) as List;
      return alertsJson
          .map((json) => FtcAlert.fromJson(json))
          .toList();
    } catch (e) {
      print('Error retrieving cached alerts: $e');
      return [];
    }
  }

  Future<bool> shouldFetchFreshData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getString(_lastFetchTimeKey);
      if (lastFetchTime == null) return true;

      final lastFetch = DateTime.parse(lastFetchTime);
      final now = DateTime.now();
      return now.difference(lastFetch).inHours >= _cacheDurationHours;
    } catch (e) {
      print('Error checking cache time: $e');
      return true;
    }
  }
}