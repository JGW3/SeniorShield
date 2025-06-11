enum PhoneCheckStatus { safe, suspicious, scam, unknown }

extension PhoneCheckStatusExtension on PhoneCheckStatus {
  static PhoneCheckStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return PhoneCheckStatus.safe;
      case 'suspicious':
        return PhoneCheckStatus.suspicious;
      case 'scam':
        return PhoneCheckStatus.scam;
      default:
        return PhoneCheckStatus.unknown;
    }
  }

  String get name {
    return toString().split('.').last;
  }
}

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