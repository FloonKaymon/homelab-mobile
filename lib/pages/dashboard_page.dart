import 'package:flutter/material.dart';
import '../models/module_status.dart';

class DashboardPage extends StatelessWidget {
  final List<ModuleStatus> modules;

  const DashboardPage({super.key, required this.modules});

  int get _totalCpuUsage {
    return modules.fold(0, (sum, module) => sum + module.cpuUsage);
  }

  int get _activeModulesCount {
    return modules.where((m) => m.active).length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildTotalCpuCard(context),
          const SizedBox(height: 24),
          _buildStatsGrid(context),
          const SizedBox(height: 24),
          _buildModulesOverview(context),
        ],
      ),
    );
  }

  Widget _buildTotalCpuCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Utilisation CPU Globale',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              '$_totalCpuUsage%',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalCpuUsage / 100,
                minHeight: 12,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
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
          color: const Color(0xFF558B2F),
        ),
        _buildStatCard(
          context,
          title: 'Modules Arrêtés',
          value: (modules.length - _activeModulesCount).toString(),
          icon: Icons.pause_circle,
          color: const Color(0xFF78909C),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesOverview(BuildContext context) {
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

  Widget _buildModulePreview(ModuleStatus module) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              module.active ? Icons.check_circle : Icons.pause_circle,
              color: module.active ? const Color(0xFF558B2F) : const Color(0xFF78909C),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: module.cpuUsage / 100,
                      minHeight: 6,
                      color: const Color(0xFF455A64),
                      backgroundColor: const Color(0xFFB0BEC5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${module.cpuUsage}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
