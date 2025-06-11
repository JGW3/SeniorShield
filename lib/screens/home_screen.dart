import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../screens/chat_screen.dart';
import '../screens/check_number_screen.dart';
import '../screens/ftc_alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/report_number_screen.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final User? user;

  const HomeScreen({
    Key? key,
    required this.isLoggedIn,
    this.user,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isSigningIn = false;

  Future<void> _signOut() async {
    setState(() {
      _isSigningIn = true;
    });

    await _auth.signOut();
    await _googleSignIn.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (mounted) {
      setState(() {
        _isSigningIn = false;
      });
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final displayName = (user?.displayName ?? 'there').split(' ').first;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SeniorShield', style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            iconSize: 32,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          if (widget.isLoggedIn)
            IconButton(
              iconSize: 32,
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isLoggedIn && user != null)
            Container(
              padding: const EdgeInsets.all(24),
              color: colorScheme.surfaceVariant.withOpacity(0.4),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    radius: 30,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                    child: user.photoURL == null
                        ? Icon(Icons.person, size: 30, color: colorScheme.onSurface)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            color: widget.isLoggedIn
                ? colorScheme.secondaryContainer.withOpacity(0.5)
                : colorScheme.tertiaryContainer.withOpacity(0.5),
            child: Text(
              widget.isLoggedIn
                  ? 'You are signed in. Your chats will be saved.'
                  : 'Not signed in. Your chats will not be saved.',
              style: TextStyle(
                fontSize: 18,
                color: widget.isLoggedIn
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onTertiaryContainer,
              ),
            ),
          ),

          if (!widget.isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(24),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login, size: 28),
                label: const Text('Sign in', style: TextStyle(fontSize: 20)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  minimumSize: Size(double.infinity, 56), // Set the width to match navigation buttons
                  side: BorderSide(color: Theme.of(context).primaryColor, width: 2), // Outline border
                ),
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hello $displayName 👋',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _NavigationButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    description: 'Ask questions about scams and alerts',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(username: user?.uid ?? 'User'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _NavigationButton(
                    icon: Icons.article,
                    label: 'Alerts',
                    description: 'Check latest scam alerts',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FtcAlertsScreen()),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _NavigationButton(
                    icon: Icons.phone,
                    label: 'Check Number',
                    description: 'See if a number is a scam',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckPhoneNumberScreen()),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _NavigationButton(
                    icon: Icons.warning,
                    label: 'Report Number',
                    description: 'Report a scam number',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportNumberScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPressed;

  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $description',
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(24),
          textStyle: const TextStyle(fontSize: 20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description, style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 28),
          ],
        ),
      ),
    );
  }
}
