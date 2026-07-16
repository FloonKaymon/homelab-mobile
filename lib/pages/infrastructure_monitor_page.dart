import 'dart:async';

import 'package:flutter/material.dart';

import '../models/modulabs_module.dart';
import '../models/telemetry_data.dart';
import '../services/module_service.dart';
import '../services/telemetry_service.dart';
import 'admin_page.dart';
import 'dashboard_page.dart';
import 'modules_page.dart';
import 'events_page.dart';
import 'settings_page.dart' show SettingsPage, NotificationPreference;

class InfrastructureMonitorPage extends StatefulWidget {
  final String baseUrl;
  final String token;
  final bool isAdmin;
  final VoidCallback onDisconnect;
  final VoidCallback onLogout;

  const InfrastructureMonitorPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.isAdmin,
    required this.onDisconnect,
    required this.onLogout,
  });

  @override
  State<InfrastructureMonitorPage> createState() => _InfrastructureMonitorPageState();
}

class _InfrastructureMonitorPageState extends State<InfrastructureMonitorPage> {
  List<ModulabsModule> _modules = [];
  final Set<String> _togglingIds = {};
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;
  NotificationPreference _notificationPreference = NotificationPreference.all;

  TelemetryData? _telemetry;
  bool _telemetryLoading = true;
  String? _telemetryError;
  Timer? _telemetryTimer;

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadTelemetry();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadTelemetry());
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTelemetry() async {
    if (_telemetry == null && mounted) {
      setState(() => _telemetryLoading = true);
    }
    try {
      final telemetry = await TelemetryService.fetchTelemetry(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _telemetry = telemetry;
        _telemetryLoading = false;
        _telemetryError = null;
      });
    } on UnauthorizedException {
      widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _telemetryLoading = false;
        _telemetryError = 'Telemetry unavailable.';
      });
    }
  }

  Future<void> _loadModules() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final modules = await ModuleService.fetchModules(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _loading = false;
      });
    } on UnauthorizedException {
      widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load modules from Modulabs.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleModule(ModulabsModule module) async {
    setState(() => _togglingIds.add(module.id));
    try {
      if (module.isActive) {
        await ModuleService.stopModule(widget.baseUrl, widget.token, module.id);
      } else {
        await ModuleService.startModule(widget.baseUrl, widget.token, module.id);
      }
      await _loadModules();
    } on UnauthorizedException {
      widget.onLogout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _togglingIds.remove(module.id));
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(
          modules: _modules,
          loading: _loading,
          error: _error,
          onRetry: _loadModules,
          telemetry: _telemetry,
          telemetryLoading: _telemetryLoading,
          telemetryError: _telemetryError,
          onRetryTelemetry: _loadTelemetry,
        );
      case 1:
        return ModulesPage(
          modules: _modules,
          loading: _loading,
          error: _error,
          togglingIds: _togglingIds,
          onToggleModule: _toggleModule,
          onRetry: _loadModules,
        );
      case 2:
        return EventsPage(baseUrl: widget.baseUrl, token: widget.token, onLogout: widget.onLogout);
      case 3:
        return SettingsPage(
          currentPreference: _notificationPreference,
          onPreferenceChanged: (preference) {
            setState(() {
              _notificationPreference = preference;
            });
          },
          modulabsUrl: widget.baseUrl,
          token: widget.token,
          onDisconnect: widget.onDisconnect,
          onLogout: widget.onLogout,
        );
      case 4:
        if (widget.isAdmin) {
          return AdminPage(baseUrl: widget.baseUrl, token: widget.token, onLogout: widget.onLogout);
        }
        return DashboardPage(
          modules: _modules,
          loading: _loading,
          error: _error,
          onRetry: _loadModules,
          telemetry: _telemetry,
          telemetryLoading: _telemetryLoading,
          telemetryError: _telemetryError,
          onRetryTelemetry: _loadTelemetry,
        );
      default:
        return DashboardPage(
          modules: _modules,
          loading: _loading,
          error: _error,
          onRetry: _loadModules,
          telemetry: _telemetry,
          telemetryLoading: _telemetryLoading,
          telemetryError: _telemetryError,
          onRetryTelemetry: _loadTelemetry,
        );
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadModules(), _loadTelemetry()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modulabs'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refreshAll,
          ),
        ],
      ),
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.widgets),
            label: 'Modules',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Events',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          if (widget.isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
