import 'package:flutter/material.dart';
import '../models/homelab_module.dart';
import '../models/telemetry_data.dart';
import '../theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  final List<HomelabModule> modules;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;

  final TelemetryData? telemetry;
  final bool telemetryLoading;
  final String? telemetryError;
  final Future<void> Function() onRetryTelemetry;

  const DashboardPage({
    super.key,
    required this.modules,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.telemetry,
    required this.telemetryLoading,
    required this.telemetryError,
    required this.onRetryTelemetry,
  });

  int get _activeModulesCount => modules.where((m) => m.isActive).length;

  @override
  Widget build(BuildContext context) {
    if (loading && modules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && modules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.faint(0.4)),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRetry,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildResourcesSection(context),
            const SizedBox(height: 24),
            _buildStatsGrid(context),
            const SizedBox(height: 24),
            _buildModulesOverview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesSection(BuildContext context) {
    if (telemetryLoading && telemetry == null) {
      return Card(
        color: AppColors.base100,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (telemetryError != null && telemetry == null) {
      return Card(
        color: AppColors.base100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.faint(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.faint(0.4)),
              const SizedBox(width: 12),
              Expanded(child: Text(telemetryError!)),
              TextButton(onPressed: onRetryTelemetry, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final data = telemetry;
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RESSOURCES SYSTÈME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.faint(0.5),
              ),
            ),
            Text(
              'Uptime: ${data.formattedUptime}',
              style: TextStyle(fontSize: 12, color: AppColors.faint(0.4)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          title: 'CPU',
          icon: Icons.memory,
          fraction: (data.cpuPercent / 100).clamp(0, 1).toDouble(),
          subtitle: '${data.cpuPercent.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          title: 'Mémoire',
          icon: Icons.developer_board,
          fraction: data.ram.usedFraction,
          subtitle: '${data.ram.usedGb.toStringAsFixed(1)} / ${data.ram.totalGb.toStringAsFixed(1)} Go',
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          title: 'Stockage',
          icon: Icons.storage,
          fraction: data.disk.usedFraction,
          subtitle: '${data.disk.usedGb.toStringAsFixed(1)} / ${data.disk.totalGb.toStringAsFixed(1)} Go',
        ),
      ],
    );
  }

  Widget _buildResourceCard({
    required String title,
    required IconData icon,
    required double fraction,
    required String subtitle,
  }) {
    final color = _fractionColor(fraction);
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.faint(0.6))),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _fractionColor(double fraction) {
    if (fraction >= 0.9) return AppColors.error;
    if (fraction >= 0.7) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          context,
          title: 'Modules Actifs',
          value: _activeModulesCount.toString(),
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        _buildStatCard(
          context,
          title: 'Modules Arrêtés',
          value: (modules.length - _activeModulesCount).toString(),
          icon: Icons.pause_circle,
          color: AppColors.faint(0.5),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.faint(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesOverview(BuildContext context) {
    if (modules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: Text('Aucun module trouvé.', style: TextStyle(color: AppColors.faint(0.4))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu des Modules',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...modules.map((module) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildModulePreview(module),
          );
        }),
      ],
    );
  }

  Widget _buildModulePreview(HomelabModule module) {
    final (label, color, icon) = statusVisuals(module.status);
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (module.version.isNotEmpty)
                    Text(
                      'v${module.version}',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.faint(0.4)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
