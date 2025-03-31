// lib/models/ftc_alert.dart
class FtcAlert {
  final String title;
  final DateTime date;
  final String summary;
  final String link;

  FtcAlert({
    required this.title,
    required this.date,
    required this.summary,
    required this.link,
  });

  factory FtcAlert.fromJson(Map<String, dynamic> json) {
    return FtcAlert(
      title: json['headline'] ?? json['title'] ?? '',
      date: DateTime.parse(json['date']),
      summary: json['summary'] ?? '',
      link: json['url'] ?? json['link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': title,
      'date': date.toIso8601String(),
      'summary': summary,
      'url': link,
    };
  }
}