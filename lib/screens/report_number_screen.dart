import 'package:flutter/material.dart';
import '../services/report_number_service.dart';

class ReportNumberScreen extends StatefulWidget {
  const ReportNumberScreen({Key? key}) : super(key: key);

  @override
  State<ReportNumberScreen> createState() => _ReportNumberScreenState();
}

class _ReportNumberScreenState extends State<ReportNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _reportService = ReportNumberService();

  String _reportType = 'Scam';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _reportTypes = ['Scam', 'Suspicious', 'Other'];

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitted = false;
    });

    try {
      await _reportService.submitReport(
        phone: _phoneController.text.trim(),
        type: _reportType,
        description: _descriptionController.text.trim(),
      );

      setState(() {
        _submitted = true;
        _phoneController.clear();
        _descriptionController.clear();
        _reportType = 'Scam';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Phone Number', style: TextStyle(fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Help others by reporting scam or suspicious phone numbers.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      final cleaned = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                      if (cleaned.isEmpty) return 'Enter a phone number';
                      if (cleaned.length != 10) return 'Enter a valid 10-digit U.S. number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _reportType,
                    icon: const Icon(Icons.arrow_drop_down),
                    decoration: InputDecoration(
                      labelText: 'Report Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: _reportTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _reportType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Additional Details (optional)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitReport,
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.report),
                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Report',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_submitted)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text(
                          '✅ Thank you! Your report has been submitted.',
                          style: TextStyle(color: Colors.green, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
