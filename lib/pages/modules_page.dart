import 'package:flutter/material.dart';
import '../models/module_status.dart';

class ModulesPage extends StatelessWidget {
  final List<ModuleStatus> modules;
  final Function(int) onToggleModule;

  const ModulesPage({
    super.key,
    required this.modules,
    required this.onToggleModule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Gestion des Modules',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: modules.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final module = modules[index];
                return _buildModuleCard(context, module, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, ModuleStatus module, int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  module.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    module.active ? 'Actif' : 'Arrêté',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: module.active ? const Color(0xFFE8F5E9) : const Color(0xFFECEFF1),
                  avatar: Icon(
                    module.active ? Icons.check_circle : Icons.pause_circle,
                    color: module.active ? const Color(0xFF558B2F) : const Color(0xFF90A4AE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Utilisation CPU', '${module.cpuUsage}%'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: module.cpuUsage / 100,
                minHeight: 10,
                color: module.active ? const Color(0xFF455A64) : const Color(0xFF90A4AE),
                backgroundColor: const Color(0xFFB0BEC5),
              ),
            ),
            if (module.active) ...[
              const SizedBox(height: 12),
              _buildStatRow('Temps actif', module.formattedUptime),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onToggleModule(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: module.active ? const Color(0xFF62757F) : const Color(0xFF558B2F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  module.active ? 'Arrêter le module' : 'Relancer le module',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
