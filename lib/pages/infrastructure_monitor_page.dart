import 'dart:async';
import 'package:flutter/material.dart';

import '../models/module_status.dart';
import 'dashboard_page.dart';
import 'modules_page.dart';
import 'events_page.dart';
import 'settings_page.dart' show SettingsPage, NotificationPreference;

class InfrastructureMonitorPage extends StatefulWidget {
  const InfrastructureMonitorPage({super.key});

  @override
  State<InfrastructureMonitorPage> createState() => _InfrastructureMonitorPageState();
}

class _InfrastructureMonitorPageState extends State<InfrastructureMonitorPage> {
  late List<ModuleStatus> _modules;
  late Timer _timer;
  int _selectedIndex = 0;
  NotificationPreference _notificationPreference = NotificationPreference.all;

  @override
  void initState() {
    super.initState();
    _modules = [
      const ModuleStatus(name: 'Photo', defaultCpuUsage: 24, active: true, uptimeSeconds: 1500),
      const ModuleStatus(name: 'Stockage', defaultCpuUsage: 18, active: true, uptimeSeconds: 3600),
      const ModuleStatus(name: 'Vidéo', defaultCpuUsage: 32, active: true, uptimeSeconds: 2400),
    ];
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        for (int i = 0; i < _modules.length; i++) {
          if (_modules[i].active) {
            _modules[i] = _modules[i].copyWith(
              uptimeSeconds: _modules[i].uptimeSeconds + 1,
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _toggleModule(int index) {
    setState(() {
      final module = _modules[index];
      if (module.active) {
        _modules[index] = module.copyWith(active: false, uptimeSeconds: 0);
      } else {
        _modules[index] = module.copyWith(active: true, uptimeSeconds: 0);
      }
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(modules: _modules);
      case 1:
        return ModulesPage(modules: _modules, onToggleModule: _toggleModule);
      case 2:
        return const EventsPage();
      case 3:
        return SettingsPage(
          currentPreference: _notificationPreference,
          onPreferenceChanged: (preference) {
            setState(() {
              _notificationPreference = preference;
            });
          },
        );
      default:
        return DashboardPage(modules: _modules);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homelab Monitor'),
        centerTitle: true,
        elevation: 0,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.widgets),
            label: 'Modules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Événements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
