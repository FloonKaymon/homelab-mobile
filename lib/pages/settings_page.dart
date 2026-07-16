import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/modulabs_connection.dart';
import '../theme/app_theme.dart';
import 'change_password_page.dart';

enum NotificationPreference {
  all,
  alertsOnly,
  none,
}

class SettingsPage extends StatefulWidget {
  final NotificationPreference currentPreference;
  final Function(NotificationPreference) onPreferenceChanged;
  final String modulabsUrl;
  final String token;
  final VoidCallback onDisconnect;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
    required this.currentPreference,
    required this.onPreferenceChanged,
    required this.modulabsUrl,
    required this.token,
    required this.onDisconnect,
    required this.onLogout,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late NotificationPreference _selectedPreference;
  String? _userEmail;
  String? _connectionName;

  @override
  void initState() {
    super.initState();
    _selectedPreference = widget.currentPreference;
    AuthService.getUserEmail().then((email) {
      if (mounted) setState(() => _userEmail = email);
    });
    _loadConnectionName();
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
          RadioGroup<NotificationPreference>(
            groupValue: _selectedPreference,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPreference = value);
                widget.onPreferenceChanged(value);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNotificationOption(
                  title: 'All',
                  subtitle: 'Receive every notification',
                  value: NotificationPreference.all,
                ),
                const SizedBox(height: 12),
                _buildNotificationOption(
                  title: 'Alerts only',
                  subtitle: 'Receive only important alerts',
                  value: NotificationPreference.alertsOnly,
                ),
                const SizedBox(height: 12),
                _buildNotificationOption(
                  title: 'None',
                  subtitle: 'Disable every notification',
                  value: NotificationPreference.none,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoCard(),
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

  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required NotificationPreference value,
  }) {
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: RadioListTile<NotificationPreference>(
        value: value,
        activeColor: AppColors.primary,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.faint(0.55))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      color: AppColors.primary.withValues(alpha: 0.08),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'About notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getInfoText(),
              style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.faint(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  String _getInfoText() {
    switch (_selectedPreference) {
      case NotificationPreference.all:
        return 'You will receive every notification: module starts, stops, CPU alerts, and other system events.';
      case NotificationPreference.alertsOnly:
        return 'You will receive only important alerts: CPU threshold breaches, system errors, and critical incidents.';
      case NotificationPreference.none:
        return 'No notifications will be received. You can still check the event history in the "Events" tab.';
    }
  }
}
