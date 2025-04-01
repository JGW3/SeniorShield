import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/ftc_alert.dart';

class FtcScraperService {
  final String baseUrl = 'https://consumer.ftc.gov/consumer-alerts';

  Future<List<FtcAlert>> fetchAlerts({int page = 0}) async {
    try {
      final url = page == 0 ? baseUrl : '$baseUrl?page=$page';
    //  print('Fetching alerts from $url (page $page)');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
      //  print('Response received with status: ${response.statusCode}');
        var alerts = _parseAlerts(response.body);

        // Limit to 20 alerts per page as required
        if (alerts.length > 20) {
      //    print('Limiting results to 20 per page (found ${alerts.length})');
          alerts = alerts.sublist(0, 20);
        }

        // Deduplicate alerts based on URL
        final Map<String, FtcAlert> uniqueAlerts = {};
        for (var alert in alerts) {
          if (!uniqueAlerts.containsKey(alert.link) ||
              alert.summary.length < uniqueAlerts[alert.link]!.summary.length) {
            uniqueAlerts[alert.link] = alert;
          }
        }

        return uniqueAlerts.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      } else {
        throw Exception('Failed to load FTC alerts: ${response.statusCode}');
      }
    } catch (e) {
    //  print('Error in fetchAlerts: $e');
      throw Exception('Error fetching alerts: $e');
    }
  }

  List<FtcAlert> _parseAlerts(String htmlString) {
    final document = parser.parse(htmlString);

    // Print the first 100 characters of the document to debug
  //  print('HTML preview: ${htmlString.substring(0, htmlString.length > 100 ? 100 : htmlString.length)}...');

    // Try multiple selectors to find alert articles
    final alertSelectors = [
      'article.consumer-alert',
      '.views-row',
      'div.consumer-alert',
      '.view-content > div',  // More generic
      'main article'          // Very generic
    ];

    List<Element> alertElements = [];

    for (final selector in alertSelectors) {
      alertElements = document.querySelectorAll(selector);
    //  print('Selector "$selector" found ${alertElements.length} elements');

      if (alertElements.isNotEmpty) {
        break;
      }
    }

    // If still empty, try the XPath approach
    if (alertElements.isEmpty) {
    //  print('Using XPath approach');
      final mainContent = document.querySelector('main');
      if (mainContent != null) {
        // Navigate down the DOM structure based on the XPath
        final divRegion = mainContent.querySelector('div.region--content');
        final divElements = divRegion?.querySelectorAll('div') ?? [];
        final alertContainer = divElements
            .where((div) => div.text?.contains('Consumer Alert') ?? false)
            .toList();

        if (alertContainer.isNotEmpty) {
        //  print('Found ${alertContainer.length} potential containers');
          alertElements = alertContainer;
        }
      }
    }

    if (alertElements.isEmpty) {
    //  print('No alert elements found with any selector');
      return [];
    }

  //  print('Processing ${alertElements.length} alerts');
    final alerts = alertElements.map((element) {
      // Extract title from heading element
      final titleElement = element.querySelector('h2, h3');
      final title = titleElement?.text?.trim() ?? 'No title';

      // Extract date element
      final dateElement = element.querySelector('.date, time, .field--name-field-date');
      final dateText = dateElement?.text?.trim() ?? '';

      // Extract link
      final linkElement = element.querySelector('a');
      final link = linkElement?.attributes['href'] ?? '';
      final fullLink = link.startsWith('http') ? link : 'https://consumer.ftc.gov$link';

      // Extract summary using more specific selector
      final summaryElement = element.querySelector('.node__content p, .views-field-body p, .field--name-body p');
      String summary = summaryElement?.text?.trim() ?? '';

      // If summary is empty, try additional selectors
      if (summary.isEmpty) {
        // Target deeper nested content
        final nestedContent = element.querySelector('.field--type-text-long, .field--name-body');
        if (nestedContent != null) {
          summary = nestedContent.text.trim();
        }

        // If still empty, try different nested structure
        if (summary.isEmpty) {
          final contentDiv = element.querySelectorAll('div div');
          if (contentDiv.length >= 3) {
            summary = contentDiv[2].text.trim();
          }
        }
      }

      // Parse date
      DateTime date = _parseDate(dateText);

      return FtcAlert(
        title: title,
        link: fullLink,
        date: date,
        summary: summary,
      );
    }).toList();

    // Sort alerts by date - newest first
    alerts.sort((a, b) => b.date.compareTo(a.date));

    return alerts;
  }

  DateTime _parseDate(String dateText) {
    if (dateText.isEmpty) return DateTime.now();

    try {
      final dateRegex = RegExp(r'(\w+) (\d+), (\d{4})');
      final match = dateRegex.firstMatch(dateText);
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
    //  print('Date parsing error: $e');
    }

    return DateTime.now();
  }
}