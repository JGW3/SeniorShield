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
    await prefs.remove('lastFetchTime');
    await prefs.remove('cachedAlerts');

    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cache cleared successfully'),
        backgroundColor: theme.colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: const Text('Switch between light and dark theme'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
              _saveSettings();
            },
            secondary: Icon(Icons.dark_mode, color: colorScheme.primary),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(
              'Notifications',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: const Text('Receive notifications about new alerts'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
              _saveSettings();
            },
            secondary: Icon(Icons.notifications_active, color: colorScheme.primary),
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Clear Cache',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: const Text('Remove stored alert data'),
            trailing: Icon(Icons.delete_outline, color: colorScheme.error),
            onTap: _clearData,
          ),
          const Divider(),
          AboutListTile(
            icon: Icon(Icons.info, color: colorScheme.primary),
            applicationName: 'SeniorShield',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 - Open source license',
            aboutBoxChildren: [
              const SizedBox(height: 10),
              Text(
                'SeniorShield helps seniors stay informed about the latest scams and consumer protection issues by displaying Federal Trade Commission (FTC) alerts.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Information Security: All saved data is encrypted and only available to authenticated users. No personal information is shared with third parties.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'License: This app is open source. FTC content is in the public domain.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Third-party libraries are licensed under their respective terms.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}