// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/ftc_alerts_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final GoogleSignInAccount? user;

  const HomeScreen({
    Key? key,
    required this.isLoggedIn,
    this.user,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isSigningIn = false;

  Future<void> _signOut() async {
    await _googleSignIn.signOut();

    // Clear persistent login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> _signIn() async {
    setState(() => _isSigningIn = true);

    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user != null && mounted) {
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        Navigator.of(context).pushReplacementNamed('/home', arguments: {
          'isLoggedIn': true,
          'user': user,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SeniorShield'),
        actions: [
          // Add settings icon before logout
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          if (widget.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Sign out',
            ),
        ],
      ),
      body: Column(
        children: [
          // User profile section
          if (widget.isLoggedIn && widget.user != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.user!.photoUrl ?? ''),
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    child: widget.user!.photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user!.displayName ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(widget.user!.email),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: widget.isLoggedIn ? Colors.green.shade100 : Colors.orange.shade100,
            child: Text(
              widget.isLoggedIn
                  ? 'Logged in: Your conversations will be saved'
                  : 'Not logged in: Your conversations will not be saved',
              style: TextStyle(
                color: widget.isLoggedIn ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),

          // Login button for non-logged in users
          if (!widget.isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isSigningIn ? null : _signIn,
                icon: const Icon(Icons.login),
                label: _isSigningIn
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
            ),

          // Main content with navigation buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome to SeniorShield',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Chatbot button
                  _NavigationButton(
                    icon: Icons.chat,
                    label: 'Chatbot',
                    description: 'Ask questions about FTC alerts',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // FTC Alerts button
                  _NavigationButton(
                    icon: Icons.article,
                    label: 'FTC Consumer Alerts',
                    description: 'Browse recent FTC alerts and advisories',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FtcAlertsScreen()),
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}