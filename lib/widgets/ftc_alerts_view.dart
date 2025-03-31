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
      // Debug scroll position
      print('Scroll position: ${_scrollController.position.pixels}, max: ${_scrollController.position.maxScrollExtent}');

      // More sensitive threshold (150px from bottom)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 150) {
        print('Near bottom, can load more: ${!_isLoadingMore && _hasMoreData}');
        if (!_isLoadingMore && _hasMoreData) {
          print('LOADING MORE ALERTS - Page ${_currentPage + 1}');
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
      print('Should fetch fresh alerts? $shouldFetch');

      List<FtcAlert> alerts;
      if (shouldFetch) {
        print('Fetching fresh alerts');
        alerts = await _service.fetchAlerts();
        await _cacheService.cacheAlerts(alerts);
        print('Fetched ${alerts.length} fresh alerts');
      } else {
        print('Loading alerts from cache');
        alerts = await _cacheService.getCachedAlerts();
        print('Loaded ${alerts.length} cached alerts');
      }

      setState(() {
        _alerts = alerts;
        _isLoading = false;
        // Always assume there's more data initially
        _hasMoreData = true;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAlerts() async {
    if (_isLoadingMore || !_hasMoreData) {
      print('Skip loading more: isLoading=$_isLoadingMore, hasMore=$_hasMoreData');
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      print('Loading more alerts - page $_currentPage');
      final moreAlerts = await _service.fetchAlerts(page: _currentPage);
      print('Fetched ${moreAlerts.length} more alerts from page $_currentPage');

      setState(() {
        if (moreAlerts.isNotEmpty) {
          // Filter out duplicates
          final existingLinks = _alerts.map((a) => a.link).toSet();
          final uniqueNewAlerts = moreAlerts
              .where((alert) => !existingLinks.contains(alert.link))
              .toList();

          print('Adding ${uniqueNewAlerts.length} unique new alerts');
          _alerts.addAll(uniqueNewAlerts);

          // Only set _hasMoreData to false if we get ZERO results
          _hasMoreData = moreAlerts.isNotEmpty;
        } else {
          print('No more alerts found on page $_currentPage');
          _hasMoreData = false;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more alerts: $e');
      setState(() {
        _isLoadingMore = false;
        // Don't disable pagination on error - retry on next scroll
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