import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await _prefs;
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notifications', _notifications);
  }

  Future<void> _clearData() async {
    final prefs = await _prefs;
    // Clear only the cache data, not settings
    await prefs.remove('lastFetchTime');
    await prefs.remove('cachedAlerts');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Receive notifications about new alerts'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Remove stored alert data'),
            trailing: const Icon(Icons.delete_outline),
            onTap: _clearData,
          ),
          const Divider(),
          AboutListTile(
            icon: const Icon(Icons.info),
            applicationName: 'SeniorShield',
            applicationVersion: '1.0.0',
            applicationLegalese: '2025 - Available under open source license',
            aboutBoxChildren: const [
              SizedBox(height: 10),
              Text(
                'SeniorShield helps seniors stay informed about the latest scams and consumer protection issues by displaying Federal Trade Commission (FTC) consumer alerts.',
              ),
              SizedBox(height: 10),
              Text(
                'Information Security: We implement data encryption for all saved conversations and only store data for authenticated users. No personally identifiable information is shared with third parties.',
              ),
              SizedBox(height: 10),
              Text(
                'License: This application is provided as open source software. The FTC content displayed is in the public domain and not subject to copyright.',
              ),
              SizedBox(height: 10),
              Text(
                'Third-party libraries used in this application are subject to their respective licenses.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}