import 'package:flutter/material.dart';
import '../models/modulabs_module.dart';
import '../theme/app_theme.dart';
import '../widgets/module_icon.dart';

class ModulesPage extends StatelessWidget {
  final List<ModulabsModule> modules;
  final bool loading;
  final String? error;
  final Set<String> togglingIds;
  final void Function(ModulabsModule) onToggleModule;
  final Future<void> Function() onRetry;

  /// Bearer token, forwarded as an `Authorization` header when fetching module
  /// icons. The icon endpoint (`/api/modules/{id}/UI/icon`) runs `requireAccess`
  /// on the server, so an unauthenticated image request gets a 403 for any
  /// module that declares permissions - hence the header is required here.
  final String token;

  const ModulesPage({
    super.key,
    required this.modules,
    required this.loading,
    required this.error,
    required this.togglingIds,
    required this.onToggleModule,
    required this.onRetry,
    required this.token,
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
            'Module Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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

    if (modules.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRetry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(
                child: Text('No modules found.', style: TextStyle(color: AppColors.faint(0.4))),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: modules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildModuleCard(context, modules[index]),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, ModulabsModule module) {
    final busy = togglingIds.contains(module.id);
    final disabled = busy || module.status == ModuleRunStatus.installing;

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
                _buildIcon(module),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (module.version.isNotEmpty)
                        Text(
                          'v${module.version}',
                          style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.faint(0.4)),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(module),
              ],
            ),
            if (module.description != null && module.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                module.description!,
                style: TextStyle(fontSize: 13, color: AppColors.faint(0.6)),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: disabled ? null : () => onToggleModule(module),
                style: ElevatedButton.styleFrom(
                  backgroundColor: module.isActive ? AppColors.error : AppColors.success,
                  foregroundColor: module.isActive ? AppColors.errorContent : AppColors.successContent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: busy
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: module.isActive ? AppColors.errorContent : AppColors.successContent,
                        ),
                      )
                    : Text(
                        module.isActive ? 'Stop module' : 'Start module',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ModulabsModule module) {
    if (module.iconUrl == null) {
      return Icon(Icons.widgets, size: 32, color: AppColors.faint(0.5));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      // ModuleIcon fetches the icon with the Bearer token (the endpoint is
      // access-controlled) and renders SVG or raster depending on the response.
      child: ModuleIcon(url: module.iconUrl!, token: token, size: 32),
    );
  }

  Widget _buildStatusChip(ModulabsModule module) {
    final (label, color, icon) = statusVisuals(module.status);
    return Chip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
      avatar: Icon(icon, color: color, size: 18),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
