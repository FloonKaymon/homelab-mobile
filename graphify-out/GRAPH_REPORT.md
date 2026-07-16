# Graph Report - c:\Users\oelsc\Documents\PA\homelab-mobile  (2026-07-13)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 334 nodes · 387 edges · 20 communities (18 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d77604cc`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- main.dart
- modules_page.dart
- infrastructure_monitor_page.dart
- alert_polling_service.dart
- app_theme.dart
- dashboard_page.dart
- auth_service.dart
- module_service.dart
- settings_page.dart
- telemetry_data.dart
- login_page.dart
- modulabs_module.dart
- alert_event.dart
- GeneratedPluginRegistrant.java
- gradlew
- MainActivity
- UnauthorizedException

## God Nodes (most connected - your core abstractions)
1. `GeneratedPluginRegistrant` - 3 edges
2. `ConnectionGate` - 3 edges
3. `_ConnectionGateState` - 3 edges
4. `TelemetryData` - 3 edges
5. `ConnectionSetupPage` - 3 edges
6. `_ConnectionSetupPageState` - 3 edges
7. `InfrastructureMonitorPage` - 3 edges
8. `_InfrastructureMonitorPageState` - 3 edges
9. `LoginPage` - 3 edges
10. `_LoginPageState` - 3 edges

## Surprising Connections (you probably didn't know these)
- `InfrastructureMonitorPage` --inherits--> `StatefulWidget`  [EXTRACTED]
  lib/pages/infrastructure_monitor_page.dart → None  _Bridges community 0 → community 2_
- `LoginPage` --inherits--> `StatefulWidget`  [EXTRACTED]
  lib/pages/login_page.dart → None  _Bridges community 0 → community 10_
- `SettingsPage` --inherits--> `StatefulWidget`  [EXTRACTED]
  lib/pages/settings_page.dart → None  _Bridges community 0 → community 8_

## Import Cycles
- None detected.

## Communities (20 total, 2 thin omitted)

### Community 0 - "main.dart"
Cohesion: 0.06
Nodes (36): _baseUrl, _bootstrap, build, ConnectionGate, _ConnectionGateState, createState, _GateStage, initState (+28 more)

### Community 1 - "modules_page.dart"
Cohesion: 0.06
Nodes (33): Color, IconData, MyApp, DashboardPage, build, _buildEventCard, color, description (+25 more)

### Community 2 - "infrastructure_monitor_page.dart"
Cohesion: 0.06
Nodes (32): dashboard_page.dart, events_page.dart, baseUrl, build, _buildPage, createState, dispose, _error (+24 more)

### Community 3 - "alert_polling_service.dart"
Cohesion: 0.07
Nodes (29): alert_events_service.dart, AndroidFlutterLocalNotificationsPlugin, @pragma, auth_service.dart, AlertPollingService, _AlertPollingTaskHandler, _baseUrlKey, _channelReady (+21 more)

### Community 4 - "app_theme.dart"
Cohesion: 0.07
Nodes (26): accent, accentContent, AppColors, base100, base200, base300, baseContent, build (+18 more)

### Community 5 - "dashboard_page.dart"
Cohesion: 0.08
Nodes (23): int get, active, copyWith, cpuUsage, defaultCpuUsage, ModuleStatus, name, uptimeSeconds (+15 more)

### Community 6 - "auth_service.dart"
Cohesion: 0.09
Nodes (22): dart:async, AuthService, _emailKey, getToken, getUserEmail, login, LoginResult, logout (+14 more)

### Community 7 - "module_service.dart"
Cohesion: 0.13
Nodes (16): api_exceptions.dart, dart:convert, AlertEventsService, fetchRecentEvents, fetchModules, _headers, ModuleService, _setRunning (+8 more)

### Community 8 - "settings_page.dart"
Cohesion: 0.11
Nodes (18): build, _buildAccountCard, _buildConnectionCard, _buildInfoCard, _buildNotificationOption, _confirmDisconnect, createState, currentPreference (+10 more)

### Community 9 - "telemetry_data.dart"
Cohesion: 0.11
Nodes (17): double get, activeModulesCount, coreStorageUsedGb, coreUsedGb, cpuPercent, disk, DiskInfo, fromJson (+9 more)

### Community 10 - "login_page.dart"
Cohesion: 0.12
Nodes (16): baseUrl, build, createState, dispose, _emailController, _errorMessage, _loading, _login (+8 more)

### Community 11 - "modulabs_module.dart"
Cohesion: 0.13
Nodes (14): bool get, description, fromJson, hasParams, iconUrl, id, isActive, isBusy (+6 more)

### Community 12 - "alert_event.dart"
Cohesion: 0.14
Nodes (13): AlertEvent, fromJson, id, metric, operator, operatorSymbol, resolved, ruleName (+5 more)

### Community 13 - "GeneratedPluginRegistrant.java"
Cohesion: 0.60
Nodes (3): GeneratedPluginRegistrant, FlutterEngine, Keep

### Community 14 - "gradlew"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

## Knowledge Gaps
- **226 isolated node(s):** `_GateStage`, `_stage`, `_baseUrl`, `_token`, `main` (+221 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TelemetryData` connect `telemetry_data.dart` to `infrastructure_monitor_page.dart`, `dashboard_page.dart`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **Why does `NotificationPreference` connect `settings_page.dart` to `infrastructure_monitor_page.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `_GateStage`, `_stage`, `_baseUrl` to the rest of the system?**
  _226 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `main.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.059743954480796585 - nodes in this community are weakly interconnected._
- **Should `modules_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05873015873015873 - nodes in this community are weakly interconnected._
- **Should `infrastructure_monitor_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0625 - nodes in this community are weakly interconnected._
- **Should `alert_polling_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06666666666666667 - nodes in this community are weakly interconnected._