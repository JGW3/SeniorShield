import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.initialize();
  await Firebase.initializeApp();

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

  final Color metallicBlue = const Color(0xFF007BA7); // Steel-like metallic blue

  @override
  void initState() {
    super.initState();
    _darkMode = widget.darkMode;
    _listenToPreferenceChanges();
  }

  void _listenToPreferenceChanges() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      final prefs = await SharedPreferences.getInstance();
      prefs.reload();

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
    final ThemeData baseLight = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: metallicBlue,
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: metallicBlue,
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: metallicBlue,
          side: BorderSide(color: metallicBlue, width: 2),
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: metallicBlue,
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
      useMaterial3: true,
    );

    final ThemeData baseDark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: metallicBlue,
        brightness: Brightness.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: metallicBlue,
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: metallicBlue,
          side: BorderSide(color: metallicBlue, width: 2),
          textStyle: const TextStyle(fontSize: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: metallicBlue,
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'SeniorShield',
      theme: baseLight,
      darkTheme: baseDark,
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
