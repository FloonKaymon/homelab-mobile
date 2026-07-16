import 'package:flutter/material.dart';

import '../../services/admin_system_service.dart';
import '../../services/api_exceptions.dart';
import '../../theme/app_theme.dart';

/// Admin screen for system controls: restarts the backend container
/// (`POST /api/admin/restart`), mirroring the web SettingsTab's "Restart"
/// card. Brief interruption for all connected users while it happens.
class SystemPage extends StatefulWidget {
  final String baseUrl;
  final String token;
  final VoidCallback onLogout;

  const SystemPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.onLogout,
  });

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  bool _loading = true;
  bool _restartAvailable = false;
  String? _error;
  bool _restarting = false;
  bool _restartTriggered = false;

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
      final available = await AdminSystemService.fetchRestartAvailable(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _restartAvailable = available;
        _loading = false;
      });
    } on UnauthorizedException {
      widget.onLogout();
    } on ForbiddenException {
      if (!mounted) return;
      setState(() {
        _error = 'Access restricted to administrators.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load the configuration.';
        _loading = false;
      });
    }
  }

  Future<void> _confirmRestart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restart the server?'),
        content: const Text(
          'The container will restart immediately. The application will be unavailable '
          'for a few seconds for all connected users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _restarting = true;
      _error = null;
    });
    try {
      await AdminSystemService.restart(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _restartTriggered = true;
        _restarting = false;
      });
    } on UnauthorizedException {
      widget.onLogout();
    } catch (_) {
      // The connection can be cut by the restart itself before the response
      // arrives: treat that as a likely success rather than an error,
      // mirroring the web admin panel's behavior.
      if (!mounted) return;
      setState(() {
        _restartTriggered = true;
        _restarting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Card(
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
                      const Icon(Icons.power_settings_new, color: AppColors.error),
                      const SizedBox(width: 10),
                      const Text('Restart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Restarts the application container (backend + frontend). '
                    'Brief interruption during the restart. Does not recreate the container: '
                    'a change to docker-compose variables still requires manual intervention.',
                    style: TextStyle(fontSize: 13, color: AppColors.faint(0.65), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  if (!_restartAvailable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Unavailable: the Docker socket is not mounted on this deployment.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.warning),
                      ),
                    ),
                  if (_restartTriggered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Restarting... the application will be available again in a few seconds.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.success),
                      ),
                    ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: (!_restartAvailable || _restarting || _restartTriggered) ? null : _confirmRestart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.errorContent,
                        disabledBackgroundColor: AppColors.faint(0.12),
                        disabledForegroundColor: AppColors.faint(0.35),
                      ),
                      icon: _restarting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.errorContent),
                            )
                          : const Icon(Icons.power_settings_new, size: 18),
                      label: const Text('Restart the server'),
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
