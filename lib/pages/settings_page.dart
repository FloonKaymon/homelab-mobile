import 'package:flutter/material.dart';

import '../services/alert_stream_service.dart';
import '../services/auth_service.dart';
import '../services/modulabs_connection.dart';
import '../services/notification_coordinator.dart';
import '../theme/app_theme.dart';
import 'change_password_page.dart';

class SettingsPage extends StatefulWidget {
  final String modulabsUrl;
  final String token;
  final VoidCallback onDisconnect;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
    required this.modulabsUrl,
    required this.token,
    required this.onDisconnect,
    required this.onLogout,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _userEmail;
  String? _connectionName;
  bool _pushEnabled = true;
  bool _pushBusy = false;

  @override
  void initState() {
    super.initState();
    AuthService.getUserEmail().then((email) {
      if (mounted) setState(() => _userEmail = email);
    });
    AlertStreamService.isEnabled().then((enabled) {
      if (mounted) setState(() => _pushEnabled = enabled);
    });
    _loadConnectionName();
  }

  Future<void> _onPushToggled(bool enabled) async {
    // Optimistic flip, but block re-entry while the connection starts/stops.
    setState(() {
      _pushEnabled = enabled;
      _pushBusy = true;
    });
    try {
      await NotificationCoordinator.setEnabled(
        enabled,
        baseUrl: widget.modulabsUrl,
        token: widget.token,
      );
    } finally {
      if (mounted) setState(() => _pushBusy = false);
    }
  }

  Future<void> _loadConnectionName() async {
    final activeId = await ModulabsConnection.getActiveConnectionId();
    if (activeId == null) return;
    final saved = await ModulabsConnection.getSavedConnections();
    final match = saved.where((c) => c.id == activeId);
    if (mounted && match.isNotEmpty) {
      setState(() => _connectionName = match.first.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          const Text(
            'Connection',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildConnectionCard(context),
          const SizedBox(height: 16),
          _buildAccountCard(context),
          const SizedBox(height: 32),
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPushCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.dns_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _connectionName ?? 'Modulabs server',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.modulabsUrl,
                    style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppColors.faint(0.5)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _confirmDisconnect(context),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail ?? '...',
                    style: TextStyle(fontSize: 13, color: AppColors.faint(0.5)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordPage(
                        baseUrl: widget.modulabsUrl,
                        token: widget.token,
                        forced: false,
                        onDone: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  child: const Text('Password'),
                ),
                TextButton(
                  onPressed: widget.onLogout,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change server'),
        content: const Text(
          'You will be signed out of Modulabs. You can then pick a saved Modulabs or add a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDisconnect();
    }
  }

  Widget _buildPushCard() {
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: SwitchListTile(
        value: _pushEnabled,
        activeThumbColor: AppColors.primary,
        // Disabled while a toggle is applying so we don't restart mid-restart.
        onChanged: _pushBusy ? null : (value) => _onPushToggled(value),
        title: const Text(
          'Background alerts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'On: alerts arrive even when the app is closed, over a direct '
          'connection to your Modulabs server (requires a permanent '
          '"monitoring" notification). Off: alerts arrive only while the app is open.',
          style: TextStyle(color: AppColors.faint(0.55)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
