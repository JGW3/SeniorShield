import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportNumberService {
  final String _baseUrl = 'http://10.0.2.2:8000/report';

  Future<void> submitReport({
    required String phone,
    required String type,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'type': type,
        'description': description ?? '',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to submit report');
    }
  }
}