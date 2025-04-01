import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.initialize();

  // Load dark mode preference
  final prefs = await SharedPreferences.getInstance();
  final darkMode = prefs.getBool('darkMode') ?? false;

  runApp(MyApp(darkMode: darkMode));
}

class MyApp extends StatefulWidget {
  final bool darkMode;

  const MyApp({super.key, required this.darkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.darkMode;
    _listenToPreferenceChanges();
  }

  void _listenToPreferenceChanges() {
    // Set up a listener to update theme when settings change
    Future.delayed(const Duration(milliseconds: 100), () async {
      final prefs = await SharedPreferences.getInstance();
      prefs.reload();

      // Check periodically for changes
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 500));
        final darkModePref = prefs.getBool('darkMode') ?? false;

        if (darkModePref != _darkMode && mounted) {
          setState(() {
            _darkMode = darkModePref;
          });
        }
        return mounted;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeniorShield',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HomeScreen(
            isLoggedIn: args?['isLoggedIn'] ?? false,
            user: args?['user'],
          );
        },
      },
    );
  }
}