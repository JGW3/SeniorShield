// lib/widgets/ftc_alerts_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ftc_alert.dart';
import '../services/ftc_scraper_service.dart';

class FtcAlertsView extends StatefulWidget {
  const FtcAlertsView({super.key});

  @override
  State<FtcAlertsView> createState() => _FtcAlertsViewState();
}

class _FtcAlertsViewState extends State<FtcAlertsView> {
  final FtcScraperService _service = FtcScraperService();
  late Future<List<FtcAlert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _service.fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FtcAlert>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _alertsFuture = _service.fetchAlerts();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No alerts found'));
        }

        final alerts = snapshot.data!;
        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return AlertCard(alert: alert);
          },
        );
      },
    );
  }
}

class AlertCard extends StatelessWidget {
  final FtcAlert alert;

  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Published: ${dateFormat.format(alert.date)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(alert.summary),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Here you would launch the URL using url_launcher package
                },
                child: const Text('Read More'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}