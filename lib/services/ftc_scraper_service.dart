// lib/services/ftc_scraper_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ftc_alert.dart';

class FtcScraperService {
  final String url = 'https://consumer.ftc.gov/consumer-alerts';
  // In-memory cache
  static List<FtcAlert>? _cachedAlerts;
  static DateTime? _lastFetchDate;

  Future<List<FtcAlert>> fetchAlerts() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we already fetched today
    if (_lastFetchDate != null) {
      final fetchDay = DateTime(_lastFetchDate!.year, _lastFetchDate!.month, _lastFetchDate!.day);

      if (today.isAtSameMomentAs(fetchDay) && _cachedAlerts != null) {
        print('Returning cached alerts from today');
        return _cachedAlerts!;
      }
    }

    // Otherwise, fetch fresh data
    try {
      print('Fetching alerts from $url (once-per-day)');
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SeniorShieldApp/1.0 (contact@example.com)'},
      );

      if (response.statusCode == 200) {
        final alerts = _parseAlerts(response.body);
        alerts.sort((a, b) => b.date.compareTo(a.date));

        // Update in-memory cache
        _cachedAlerts = alerts;
        _lastFetchDate = now;

        return alerts;
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchAlerts: $e');

      // Return cached data if available
      if (_cachedAlerts != null) {
        return _cachedAlerts!;
      }

      throw Exception('Error fetching alerts: $e');
    }
  }

  List<FtcAlert> _parseAlerts(String htmlString) {
    final document = parser.parse(htmlString);
    final alertElements = document.querySelectorAll('.views-row');

    print('Processing ${alertElements.length} alerts');
    return alertElements.map((element) {
      // Extract each component more reliably using direct DOM queries

      // Title - look for heading elements or specific title containers
      final titleElement = element.querySelector('h2, h3, .field--name-title');
      String title = titleElement?.text?.trim() ?? 'No title';

      // Remove "Consumer Alert" prefix if present
      if (title.startsWith('Consumer Alert')) {
        title = title.replaceFirst('Consumer Alert', '').trim();
      }

      // Author - usually in a byline or author field
      final authorElement = element.querySelector('.field--name-field-author, .byline');
      String author = authorElement?.text?.trim() ?? 'Unknown';

      // Date - look for date specific containers
      final dateElement = element.querySelector('.field--name-field-date, time, .date');
      String dateText = dateElement?.text?.trim() ?? '';

      // Summary - often in a summary field or paragraph
      final summaryElement = element.querySelector('.field--name-field-summary, .summary, p:not(.date):not(.byline)');
      String summary = summaryElement?.text?.trim() ?? '';

      // For link, find the main link in the alert
      final linkElement = element.querySelector('h2 a, h3 a, a.card-title, a.content-title');
      final link = linkElement?.attributes['href'] ?? '';
      final fullLink = link.startsWith('http') ? link : 'https://consumer.ftc.gov$link';

      // Parse date
      DateTime date = _parseDate(dateText);

      return FtcAlert(
        title: title,
        link: fullLink,
        date: date,
        summary: summary,
      );
    }).toList();
  }

  DateTime _parseDate(String dateText) {
    if (dateText.isEmpty) return DateTime.now();

    try {
      // Handle format: "March 19, 2025"
      final standardRegex = RegExp(r'(\w+) (\d+), (\d{4})');
      // Handle format: "Published: March 21, 2005"
      final publishedRegex = RegExp(r'Published: (\w+) (\d+), (\d{4})');

      var match = standardRegex.firstMatch(dateText);
      if (match == null) {
        match = publishedRegex.firstMatch(dateText);
      }

      if (match != null) {
        final months = {
          'January': 1, 'February': 2, 'March': 3, 'April': 4, 'May': 5, 'June': 6,
          'July': 7, 'August': 8, 'September': 9, 'October': 10, 'November': 11, 'December': 12
        };
        final month = months[match.group(1)] ?? 1;
        final day = int.parse(match.group(2) ?? '1');
        final year = int.parse(match.group(3) ?? '2023');
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Date parsing error: $e');
    }

    return DateTime.now();
  }
}