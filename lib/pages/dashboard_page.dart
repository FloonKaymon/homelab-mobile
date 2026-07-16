import 'package:flutter/material.dart';
import '../models/modulabs_module.dart';
import '../models/telemetry_data.dart';
import '../theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  final List<ModulabsModule> modules;
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
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
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
            _buildStorageBreakdown(context),
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
              TextButton(onPressed: onRetryTelemetry, child: const Text('Retry')),
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
              'SYSTEM RESOURCES',
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
          fraction: (data.cpu.totalPercent / 100).clamp(0, 1).toDouble(),
          subtitle: '${data.cpu.totalPercent.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          title: 'Memory',
          icon: Icons.developer_board,
          fraction: data.ram.usedFraction,
          subtitle: '${data.ram.usedGb.toStringAsFixed(1)} / ${data.ram.totalGb.toStringAsFixed(1)} GB',
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          title: 'Storage',
          icon: Icons.storage,
          fraction: data.disk.usedFraction,
          subtitle: '${data.disk.usedGb.toStringAsFixed(1)} / ${data.disk.totalGb.toStringAsFixed(1)} GB',
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

  // Fixed categorical order, ported from homelab-frontend's ModuleStorageBar
  // (its own DaisyUI theme tokens), so segment colors line up conceptually
  // with the web dashboard.
  static const _moduleStorageColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    AppColors.neutral,
  ];

  Widget _buildStorageBreakdown(BuildContext context) {
    final data = telemetry;
    if (data == null) return const SizedBox.shrink();

    final sortedModules = data.perModuleStorage.where((m) => m.storageGb > 0).toList()
      ..sort((a, b) => b.storageGb.compareTo(a.storageGb));
    final maxDirectSlots = _moduleStorageColors.length;
    final visibleModules = sortedModules.take(maxDirectSlots - 1).toList();
    final overflowModules = sortedModules.skip(maxDirectSlots - 1).toList();
    final overflowGb = overflowModules.fold(0.0, (sum, m) => sum + m.storageGb);

    final segments = <(String, double, Color)>[
      ('Homelab Core', data.disk.coreStorageUsedGb, AppColors.faint(0.25)),
      for (var i = 0; i < visibleModules.length; i++)
        (visibleModules[i].name, visibleModules[i].storageGb, _moduleStorageColors[i]),
      if (overflowModules.isNotEmpty)
        ('Other (${overflowModules.length})', overflowGb, _moduleStorageColors.last),
    ];

    final total = segments.fold(0.0, (sum, s) => sum + s.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STORAGE BREAKDOWN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.faint(0.5),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.base100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.faint(0.05)),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: total <= 0
                ? Text(
                    'No storage data available.',
                    style: TextStyle(fontSize: 13, color: AppColors.faint(0.4)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              for (final segment in segments)
                                Expanded(
                                  flex: (segment.$2 * 1e6).round().clamp(1, 1 << 30),
                                  child: Container(color: segment.$3),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          for (final segment in segments)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: segment.$3, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${segment.$1}: ',
                                  style: TextStyle(fontSize: 12, color: AppColors.faint(0.7)),
                                ),
                                Text(
                                  _formatMb(segment.$2),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String _formatMb(double gb) {
    final mb = gb * 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
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
          title: 'Active Modules',
          value: _activeModulesCount.toString(),
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        _buildStatCard(
          context,
          title: 'Stopped Modules',
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
          child: Text('No modules found.', style: TextStyle(color: AppColors.faint(0.4))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modules Overview',
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

  Widget _buildModulePreview(ModulabsModule module) {
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
