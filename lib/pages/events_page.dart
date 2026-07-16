import 'package:flutter/material.dart';

import '../models/alert_event.dart';
import '../services/alert_events_service.dart';
import '../services/api_exceptions.dart';
import '../theme/app_theme.dart';

class EventsPage extends StatefulWidget {
  final String baseUrl;
  final String token;
  final VoidCallback onLogout;

  const EventsPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.onLogout,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<AlertEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await AlertEventsService.fetchEvents(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _events = page.events;
        _loading = false;
      });
    } on UnauthorizedException {
      widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load the alert history.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Events',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.faint(0.4)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(
                child: Text('No alerts yet.', style: TextStyle(color: AppColors.faint(0.4))),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _events.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildEventCard(_events[index]),
      ),
    );
  }

  Widget _buildEventCard(AlertEvent event) {
    final (icon, color) = _severityVisuals(event.severity);
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.ruleName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTriggeredAt(event.triggeredAt),
                        style: TextStyle(fontSize: 12, color: AppColors.faint(0.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.message.isNotEmpty
                  ? event.message
                  : '${event.metric} = ${event.value.toStringAsFixed(1)} (threshold ${event.threshold})',
              style: TextStyle(fontSize: 14, color: AppColors.faint(0.75)),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats the backend's `triggeredAt` (a `LocalDateTime` serialized
  /// without offset, e.g. `2026-07-13T22:29:58`) as `dd/MM/yyyy HH:mm`.
  /// The value is server wall-clock time, so it is rendered as-is without
  /// any timezone conversion. Falls back to the raw string if unparseable.
  String _formatTriggeredAt(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} '
        '${two(parsed.hour)}:${two(parsed.minute)}';
  }

  (IconData, Color) _severityVisuals(String severity) {
    return switch (severity) {
      'CRITICAL' => (Icons.error, AppColors.error),
      'HIGH' => (Icons.warning, AppColors.error),
      'MEDIUM' => (Icons.warning_amber, AppColors.warning),
      'LOW' => (Icons.info_outline, AppColors.info),
      _ => (Icons.info_outline, AppColors.faint(0.5)),
    };
  }
}
