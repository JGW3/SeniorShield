// lib/services/phone_check_service.dart
import 'dart:async';
import '../models/phone_check_result.dart';

class PhoneCheckService {
  Future<PhoneCheckResult> checkPhoneNumber(String phone) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate API delay

    // Dummy logic — replace with real API call
    if (phone.endsWith('000')) {
      return PhoneCheckResult(
        phoneNumber: phone,
        status: PhoneCheckStatus.scam,
        message: 'This number has been reported as a scam.',
      );
    } else if (phone.endsWith('123')) {
      return PhoneCheckResult(
        phoneNumber: phone,
        status: PhoneCheckStatus.suspicious,
        message: 'This number looks suspicious. Be cautious.',
      );
    } else {
      return PhoneCheckResult(
        phoneNumber: phone,
        status: PhoneCheckStatus.safe,
        message: 'No known scam reports for this number.',
      );
    }
  }
}