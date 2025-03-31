// lib/widgets/ftc_alerts_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ftc_alert.dart';
import '../services/ftc_scraper_service.dart';
import '../services/cache_service.dart';

class FtcAlertsView extends StatefulWidget {
  const FtcAlertsView({super.key});

  @override
  State<FtcAlertsView> createState() => _FtcAlertsViewState();
}

class _FtcAlertsViewState extends State<FtcAlertsView> {
  final FtcScraperService _service = FtcScraperService();
  final CacheService _cacheService = CacheService();
  late Future<List<FtcAlert>> _alertsFuture;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shouldFetch = await _cacheService.shouldFetchFreshData();
      print('Should fetch fresh data? $shouldFetch');

      // First try using cached data
      if (!shouldFetch) {
        final cachedAlerts = await _cacheService.getCachedAlerts();
        print('Loaded ${cachedAlerts.length} cached alerts');

        // If we have cached data, use it
        if (cachedAlerts.isNotEmpty) {
          print('Using cached data');
          setState(() {
            _alertsFuture = Future.value(cachedAlerts);
            _isLoading = false;
          });
          return;
        }
        // Otherwise continue to fetch fresh data
        print('Cache empty, fetching fresh data instead');
      }

      // Fetch fresh data
      final alerts = await _service.fetchAlerts();
      print('Fetched ${alerts.length} fresh alerts');
      if (alerts.isNotEmpty) {
        await _cacheService.cacheAlerts(alerts);
        setState(() {
          _alertsFuture = Future.value(alerts);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = "No alerts found from the server";
        });
      }
    } catch (e) {
      print('Error loading alerts: $e');
      // Error handling remains the same
      try {
        final cachedAlerts = await _cacheService.getCachedAlerts();
        if (cachedAlerts.isNotEmpty) {
          setState(() {
            _alertsFuture = Future.value(cachedAlerts);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = "Network error and no cached data available";
          });
        }
      } catch (fallbackError) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAlerts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<FtcAlert>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                  if (alert.link.isNotEmpty) {
                    launchUrl(Uri.parse(alert.link));
                  }
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