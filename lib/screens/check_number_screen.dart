// lib/screens/check_number_screen.dart
import 'package:flutter/material.dart';
import '../models/phone_check_result.dart';
import '../services/phone_check_service.dart';

class CheckPhoneNumberScreen extends StatefulWidget {
  const CheckPhoneNumberScreen({Key? key}) : super(key: key);

  @override
  State<CheckPhoneNumberScreen> createState() => _CheckPhoneNumberScreenState();
}

class _CheckPhoneNumberScreenState extends State<CheckPhoneNumberScreen> {
  final TextEditingController _controller = TextEditingController();
  final PhoneCheckService _service = PhoneCheckService();

  bool _isLoading = false;
  String? _error;
  PhoneCheckResult? _result;

  Future<void> _checkNumber() async {
    final phone = _controller.text.trim();

    final phoneRegex = RegExp(r'^\+?\d{7,15}$'); // allows + and 7-15 digits

    if (phone.isEmpty) {
      setState(() {
        _error = 'Please enter a phone number.';
        _result = null;
      });
      return;
    } else if (!phoneRegex.hasMatch(phone)) {
      setState(() {
        _error = 'Enter a valid phone number (7–15 digits, optional +).';
        _result = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.checkPhoneNumber(phone);
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to check number: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildResultCard(PhoneCheckResult result) {
    Color cardColor;
    IconData icon;

    switch (result.status) {
      case PhoneCheckStatus.safe:
        cardColor = Colors.green.shade100;
        icon = Icons.check_circle;
        break;
      case PhoneCheckStatus.suspicious:
        cardColor = Colors.orange.shade100;
        icon = Icons.warning_amber;
        break;
      case PhoneCheckStatus.scam:
        cardColor = Colors.red.shade100;
        icon = Icons.error;
        break;
      default:
        cardColor = Colors.grey.shade200;
        icon = Icons.help_outline;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(result.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(result.message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Phone Number')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 40),

            const Text(
              'Enter the suspicious phone number:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _checkNumber(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkNumber,
              icon: _isLoading
                  ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.search),
              label: const Text('Check Number'),
            ),
            const SizedBox(height: 24),

            // Results Section
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            if (_result != null) _buildResultCard(_result!),
          ],
        ),
      ),
    );
  }
}
