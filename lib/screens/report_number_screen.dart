import 'package:flutter/material.dart';
import '../services/local_phone_service.dart';

class ReportNumberScreen extends StatefulWidget {
  const ReportNumberScreen({Key? key}) : super(key: key);

  @override
  State<ReportNumberScreen> createState() => _ReportNumberScreenState();
}

class _ReportNumberScreenState extends State<ReportNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _reportService = LocalPhoneService();

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
      appBar: AppBar(title: const Text('Report a Phone Number')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Help others by reporting scam or suspicious phone numbers.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final cleaned = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (cleaned.isEmpty) return 'Enter a phone number';
                  if (cleaned.length != 10) return 'Enter a valid 10-digit U.S. number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _reportType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _reportType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Details (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.report),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
                ),
              ),
              if (_submitted)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Thank you! Your report has been submitted.',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}