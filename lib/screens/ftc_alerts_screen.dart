// lib/screens/ftc_alerts_screen.dart
import 'package:flutter/material.dart';
import '../widgets/ftc_alerts_view.dart';

class FtcAlertsScreen extends StatelessWidget {
  const FtcAlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTC Consumer Alerts'),
      ),
      body: const FtcAlertsView(),
    );
  }
}