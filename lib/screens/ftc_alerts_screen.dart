// lib/screens/ftc_alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ftc_alert.dart';
import '../services/ftc_scraper_service.dart';
import '../services/cache_service.dart';

class FtcAlertsScreen extends StatelessWidget {
  const FtcAlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('FTC Consumer Alerts')
      ),
      body: const FtcAlertsContent(),
    );
  }
}

class FtcAlertsContent extends StatefulWidget {
  const FtcAlertsContent({super.key});

  @override
  State<FtcAlertsContent> createState() => _FtcAlertsContentState();
}

class _FtcAlertsContentState extends State<FtcAlertsContent> {
  final FtcScraperService _service = FtcScraperService();
  final CacheService _cacheService = CacheService();
  final ScrollController _scrollController = ScrollController();
  List<FtcAlert> _alerts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();

    _scrollController.addListener(() {
      // More sensitive threshold (150px from bottom)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 150) {
        if (!_isLoadingMore && _hasMoreData) {
          _loadMoreAlerts();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
    });

    try {
      final shouldFetch = await _cacheService.shouldFetchFreshData();

      List<FtcAlert> alerts;
      if (shouldFetch) {
        alerts = await _service.fetchAlerts();
        await _cacheService.cacheAlerts(alerts);
      } else {
        alerts = await _cacheService.getCachedAlerts();
      }

      setState(() {
        _alerts = alerts;
        _isLoading = false;
        _hasMoreData = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAlerts() async {
    if (_isLoadingMore || !_hasMoreData) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final moreAlerts = await _service.fetchAlerts(page: _currentPage);

      setState(() {
        if (moreAlerts.isNotEmpty) {
          // Filter out duplicates
          final existingLinks = _alerts.map((a) => a.link).toSet();
          final uniqueNewAlerts = moreAlerts
              .where((alert) => !existingLinks.contains(alert.link))
              .toList();

          _alerts.addAll(uniqueNewAlerts);
          _hasMoreData = moreAlerts.isNotEmpty;
        } else {
          _hasMoreData = false;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
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

    if (_alerts.isEmpty) {
      return const Center(child: Text('No alerts found'));
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _alerts.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _alerts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return AlertCard(alert: _alerts[index]);
        },
      ),
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