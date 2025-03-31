// lib/models/ftc_alert.dart
// lib/models/ftc_alert.dart
class FtcAlert {
  final String title;
  final String link;
  final DateTime date;
  final String summary;

  FtcAlert({
    required this.title,
    required this.link,
    required this.date,
    required this.summary,
  });

  // Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'link': link,
      'date': date.toIso8601String(),
      'summary': summary,
    };
  }

  // Create from JSON for cache retrieval
  factory FtcAlert.fromJson(Map<String, dynamic> json) {
    return FtcAlert(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      summary: json['summary'] ?? '',
    );
  }
}