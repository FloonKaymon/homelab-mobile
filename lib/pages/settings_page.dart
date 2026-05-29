import 'package:flutter/material.dart';

enum NotificationPreference {
  all,
  alertsOnly,
  none,
}

class SettingsPage extends StatefulWidget {
  final NotificationPreference currentPreference;
  final Function(NotificationPreference) onPreferenceChanged;

  const SettingsPage({
    super.key,
    required this.currentPreference,
    required this.onPreferenceChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late NotificationPreference _selectedPreference;

  @override
  void initState() {
    super.initState();
    _selectedPreference = widget.currentPreference;
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
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

  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required NotificationPreference value,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioListTile<NotificationPreference>(
        value: value,
        groupValue: _selectedPreference,
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
        subtitle: Text(subtitle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFECEFF1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Color(0xFF37474F)),
                const SizedBox(width: 12),
                const Text(
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
              style: const TextStyle(fontSize: 13, height: 1.6),
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
