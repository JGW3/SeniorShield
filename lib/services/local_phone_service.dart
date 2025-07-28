import '../models/phone_check_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalPhoneService {
  static const String _reportsKey = 'phone_reports';
  
  // Known scam numbers database (can be expanded)
  static const Map<String, String> _knownScams = {
    "+1234567890": "Known scam number reported for fake tax calls",
    "123-456-7890": "Reported for fake charity scams",
    "(555) 123-4567": "Known telemarketing scam",
    "8001234567": "Fake tech support scam number",
    "555-0123": "IRS impersonation scam",
  };

  Future<PhoneCheckResult> checkPhoneNumber(String phone) async {
    try {
      final cleanPhone = _cleanPhoneNumber(phone);
      
      // Check against known scam database
      for (final scamNumber in _knownScams.keys) {
        if (_cleanPhoneNumber(scamNumber) == cleanPhone) {
          return PhoneCheckResult(
            phoneNumber: phone,
            status: PhoneCheckStatus.scam,
            message: "WARNING: ${_knownScams[scamNumber]}",
          );
        }
      }
      
      // Check against user reports
      final reports = await _getReports(cleanPhone);
      if (reports.isNotEmpty) {
        return PhoneCheckResult(
          phoneNumber: phone,
          status: PhoneCheckStatus.suspicious,
          message: "This number has been reported ${reports.length} time(s) for scam activity. Recent report: ${reports.last['type']}",
        );
      }
      
      // Check for suspicious patterns
      final suspiciousPattern = _checkSuspiciousPatterns(cleanPhone);
      if (suspiciousPattern != null) {
        return PhoneCheckResult(
          phoneNumber: phone,
          status: PhoneCheckStatus.suspicious,
          message: suspiciousPattern,
        );
      }
      
      return PhoneCheckResult(
        phoneNumber: phone,
        status: PhoneCheckStatus.unknown,
        message: "No reports found for this number. Stay vigilant and trust your instincts. If this number contacted you unexpectedly asking for money or personal information, it could still be a scam.",
      );
      
    } catch (e) {
      return PhoneCheckResult(
        phoneNumber: phone,
        status: PhoneCheckStatus.unknown,
        message: "Unable to check this number. If you're suspicious, don't answer and block the number.",
      );
    }
  }

  Future<void> submitReport({
    required String phone,
    required String type,
    String? description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanPhone = _cleanPhoneNumber(phone);
      
      final reportsJson = prefs.getString(_reportsKey);
      Map<String, dynamic> allReports = {};
      
      if (reportsJson != null) {
        allReports = jsonDecode(reportsJson);
      }
      
      if (!allReports.containsKey(cleanPhone)) {
        allReports[cleanPhone] = [];
      }
      
      allReports[cleanPhone].add({
        'type': type,
        'description': description ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(_reportsKey, jsonEncode(allReports));
      
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getReports(String cleanPhone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_reportsKey);
      
      if (reportsJson == null) return [];
      
      final Map<String, dynamic> allReports = jsonDecode(reportsJson);
      return List<Map<String, dynamic>>.from(allReports[cleanPhone] ?? []);
      
    } catch (e) {
      return [];
    }
  }

  String _cleanPhoneNumber(String phone) {
    // Remove all non-digit characters
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  String? _checkSuspiciousPatterns(String cleanPhone) {
    // Check for obviously fake numbers
    if (cleanPhone.length < 7) {
      return "This appears to be an incomplete phone number.";
    }
    
    // Check for repeated digits (often fake)
    if (RegExp(r'(\d)\1{6,}').hasMatch(cleanPhone)) {
      return "This number has suspicious repeated digits - likely fake.";
    }
    
    // Check for sequential numbers (often fake)
    if (RegExp(r'(01234|12345|23456|34567|45678|56789)').hasMatch(cleanPhone)) {
      return "This number contains sequential digits - likely fake.";
    }
    
    // Check for common scam area codes (update based on known patterns)
    final areaCode = cleanPhone.substring(0, 3);
    final suspiciousAreaCodes = ['999', '000', '555', '123'];
    
    if (suspiciousAreaCodes.contains(areaCode)) {
      return "This area code ($areaCode) is commonly used by scammers.";
    }
    
    return null;
  }

  // Get statistics for user dashboard
  Future<Map<String, int>> getScamStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_reportsKey);
      
      if (reportsJson == null) {
        return {
          'totalReports': 0,
          'knownScams': _knownScams.length,
          'recentReports': 0,
        };
      }
      
      final Map<String, dynamic> allReports = jsonDecode(reportsJson);
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      int recentReports = 0;
      int totalReports = 0;
      
      for (final reports in allReports.values) {
        totalReports += (reports as List).length;
        
        for (final report in reports) {
          final timestamp = DateTime.tryParse(report['timestamp'] ?? '');
          if (timestamp != null && timestamp.isAfter(weekAgo)) {
            recentReports++;
          }
        }
      }
      
      return {
        'totalReports': totalReports,
        'knownScams': _knownScams.length,
        'recentReports': recentReports,
      };
      
    } catch (e) {
      return {
        'totalReports': 0,
        'knownScams': _knownScams.length,
        'recentReports': 0,
      };
    }
  }
}