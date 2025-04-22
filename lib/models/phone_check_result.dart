// lib/models/phone_check_result.dart
enum PhoneCheckStatus { safe, suspicious, scam, unknown }

class PhoneCheckResult {
  final String phoneNumber;
  final PhoneCheckStatus status;
  final String message;

  PhoneCheckResult({
    required this.phoneNumber,
    required this.status,
    required this.message,
  });
}