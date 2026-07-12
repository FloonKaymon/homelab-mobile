import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

enum NotificationPreference {
  all,
  alertsOnly,
  none,
}

class SettingsPage extends StatefulWidget {
  final NotificationPreference currentPreference;
  final Function(NotificationPreference) onPreferenceChanged;
  final String modulabsUrl;
  final VoidCallback onDisconnect;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
    required this.currentPreference,
    required this.onPreferenceChanged,
    required this.modulabsUrl,
    required this.onDisconnect,
    required this.onLogout,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late NotificationPreference _selectedPreference;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _selectedPreference = widget.currentPreference;
    AuthService.getUserEmail().then((email) {
      if (mounted) setState(() => _userEmail = email);
    });
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
            'Paramètres',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          const Text(
            'Connexion',
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
          _buildNotificationOption(
            title: 'Tout',
            subtitle: 'Recevoir toutes les notifications',
            value: NotificationPreference.all,
          ),
          const SizedBox(height: 12),
          _buildNotificationOption(
            title: 'Alertes seulement',
            subtitle: 'Recevoir uniquement les alertes importantes',
            value: NotificationPreference.alertsOnly,
          ),
          const SizedBox(height: 12),
          _buildNotificationOption(
            title: 'Aucunes',
            subtitle: 'Désactiver toutes les notifications',
            value: NotificationPreference.none,
          ),
          const SizedBox(height: 32),
          _buildInfoCard(),
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
                  const Text(
                    'Serveur Modulabs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              child: const Text('Changer'),
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
                    'Compte',
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
            TextButton(
              onPressed: widget.onLogout,
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Se déconnecter'),
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
        title: const Text('Changer de serveur'),
        content: const Text(
          'Vous allez être déconnecté de Modulabs. Vous pourrez saisir une nouvelle adresse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Changer'),
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
        groupValue: _selectedPreference,
        activeColor: AppColors.primary,
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedPreference = newValue;
            });
            widget.onPreferenceChanged(newValue);
          }
        },
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
                  'À propos des notifications',
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
        return 'Vous recevrez toutes les notifications: démarrages, arrêts, alertes CPU, et autres événements système.';
      case NotificationPreference.alertsOnly:
        return 'Vous recevrez uniquement les alertes importantes: dépassements de seuil CPU, erreurs système, et incidents critiques.';
      case NotificationPreference.none:
        return 'Aucune notification ne sera reçue. Vous pouvez consulter l\'historique des événements dans l\'onglet "Événements".';
    }
  }
}
