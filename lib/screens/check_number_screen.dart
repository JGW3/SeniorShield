import 'package:flutter/material.dart';
import '../models/phone_check_result.dart';
import '../services/local_phone_service.dart';

class CheckPhoneNumberScreen extends StatefulWidget {
  const CheckPhoneNumberScreen({Key? key}) : super(key: key);

  @override
  State<CheckPhoneNumberScreen> createState() =>
      _CheckPhoneNumberScreenState();
}

class _CheckPhoneNumberScreenState extends State<CheckPhoneNumberScreen> {
  final TextEditingController _controller = TextEditingController();
  final LocalPhoneService _service = LocalPhoneService();

  bool _isLoading = false;
  String? _error;
  PhoneCheckResult? _result;

  Future<void> _checkNumber() async {
    final phone = _controller.text.trim();
    final phoneRegex = RegExp(r'^\+?\d{7,15}$');

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color cardColor;
    IconData icon;
    Color iconColor;

    switch (result.status) {
      case PhoneCheckStatus.safe:
        cardColor = isDark ? Colors.green.shade900 : Colors.green.shade100;
        icon = Icons.check_circle;
        iconColor = isDark ? Colors.greenAccent : Colors.green.shade800;
        break;
      case PhoneCheckStatus.suspicious:
        cardColor = isDark ? Colors.orange.shade900 : Colors.orange.shade100;
        icon = Icons.warning_amber_rounded;
        iconColor = isDark ? Colors.orangeAccent : Colors.orange.shade800;
        break;
      case PhoneCheckStatus.scam:
        cardColor = isDark ? Colors.red.shade900 : Colors.red.shade100;
        icon = Icons.error;
        iconColor = isDark ? Colors.redAccent : Colors.red.shade800;
        break;
      default:
        cardColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
        icon = Icons.help_outline;
        iconColor = isDark ? Colors.grey.shade300 : Colors.grey;
    }

    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.phoneNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check Phone Number',
          style: TextStyle(fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'Enter a suspicious phone number to check its safety:',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(fontSize: 16),
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _checkNumber(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkNumber,
                icon: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.search),
                label: Text(
                  _isLoading ? 'Checking...' : 'Check Number',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            if (_result != null) _buildResultCard(_result!),
          ],
        ),
      ),
    );
  }
}
