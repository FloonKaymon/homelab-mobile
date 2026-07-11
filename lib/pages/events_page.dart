import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = _generateEvents();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Événements',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventCard(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
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
                    color: event.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(event.icon, color: event.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.faint(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: TextStyle(fontSize: 14, color: AppColors.faint(0.75)),
            ),
          ],
        ),
      ),
    );
  }

  List<Event> _generateEvents() {
    return [
      Event(
        title: 'Module Vidéo redémarré',
        description: 'Le module Vidéo a été redémarré avec succès.',
        timestamp: 'Il y a 5 minutes',
        icon: Icons.restart_alt,
        color: AppColors.primary,
      ),
      Event(
        title: 'Alerte CPU élevée',
        description: 'L\'utilisation CPU globale a dépassé 80%.',
        timestamp: 'Il y a 12 minutes',
        icon: Icons.warning,
        color: AppColors.warning,
      ),
      Event(
        title: 'Module Photo arrêté',
        description: 'Le module Photo a été arrêté manuellement.',
        timestamp: 'Il y a 28 minutes',
        icon: Icons.pause_circle,
        color: AppColors.faint(0.5),
      ),
      Event(
        title: 'Module Stockage optimisé',
        description: 'Cache nettoyé avec succès. Espace libéré: 2.3 GB',
        timestamp: 'Il y a 1 heure',
        icon: Icons.storage,
        color: AppColors.success,
      ),
      Event(
        title: 'Démarrage système',
        description: 'Tous les modules ont été initialisés.',
        timestamp: 'Il y a 2 heures',
        icon: Icons.power_settings_new,
        color: AppColors.secondary,
      ),
      Event(
        title: 'Synchronisation complétée',
        description: 'Synchronisation des données avec le serveur terminée.',
        timestamp: 'Il y a 3 heures',
        icon: Icons.sync,
        color: AppColors.info,
      ),
    ];
  }
}

class Event {
  final String title;
  final String description;
  final String timestamp;
  final IconData icon;
  final Color color;

  Event({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
