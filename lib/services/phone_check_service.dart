import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/phone_check_result.dart';

class PhoneCheckService {
  final String _baseUrl = 'http://10.0.2.2:8000/check-phone';

  Future<PhoneCheckResult> checkPhoneNumber(String phone) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PhoneCheckResult(
        phoneNumber: data['phone_number'],
        status: PhoneCheckStatusExtension.fromString(data['status']),
        message: data['message'],
      );
    } else {
      throw Exception('Failed to check phone number');
    }
  }
}
