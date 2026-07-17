import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'pages/change_password_page.dart';
import 'pages/connection_setup_page.dart';
import 'pages/infrastructure_monitor_page.dart';
import 'pages/login_page.dart';
import 'services/alert_stream_service.dart';
import 'services/auth_service.dart';
import 'services/modulabs_connection.dart';
import 'services/notification_coordinator.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  AlertStreamService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modulabs',
      theme: buildModulabsTheme(),
      home: const ConnectionGate(),
    );
  }
}

enum _GateStage { loading, needsUrl, needsLogin, needsPasswordChange, ready }

/// Drives the app's startup flow through three steps:
/// 1. no server URL saved -> [ConnectionSetupPage]
/// 2. URL saved but no valid session -> [LoginPage]
/// 3. URL + valid session -> the monitor itself
class ConnectionGate extends StatefulWidget {
  const ConnectionGate({super.key});

  @override
  State<ConnectionGate> createState() => _ConnectionGateState();
}

class _ConnectionGateState extends State<ConnectionGate> {
  _GateStage _stage = _GateStage.loading;
  String? _baseUrl;
  String? _token;
  bool _hasAdminAccess = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final url = await ModulabsConnection.getSavedUrl();
    if (url == null) {
      if (!mounted) return;
      setState(() => _stage = _GateStage.needsUrl);
      return;
    }

    final token = await AuthService.getToken();
    // `/api/auth/me` doubles as the token-validity probe: a non-null result
    // means the stored session is still accepted, and it carries `isAdmin` and
    // the admin permissions in the same round-trip. The app is admin-only, so a
    // session whose admin access was revoked since login is dropped here too.
    final currentUser = token != null ? await AuthService.fetchCurrentUser(url, token) : null;
    if (token != null && currentUser != null && currentUser.hasAdminAccess) {
      if (!mounted) return;
      if (currentUser.mustResetPassword) {
        setState(() {
          _baseUrl = url;
          _token = token;
          _hasAdminAccess = currentUser.hasAdminAccess;
          _stage = _GateStage.needsPasswordChange;
        });
        return;
      }
      setState(() {
        _baseUrl = url;
        _token = token;
        _hasAdminAccess = currentUser.hasAdminAccess;
        _stage = _GateStage.ready;
      });
      unawaited(NotificationCoordinator.start(baseUrl: url, token: token));
      return;
    }

    await AuthService.logout();
    if (!mounted) return;
    setState(() {
      _baseUrl = url;
      _stage = _GateStage.needsLogin;
    });
  }

  void _onConnected(String baseUrl) {
    setState(() {
      _baseUrl = baseUrl;
      _stage = _GateStage.needsLogin;
    });
  }

  Future<void> _onLoggedIn() async {
    final token = await AuthService.getToken();
    final currentUser = token != null ? await AuthService.fetchCurrentUser(_baseUrl!, token) : null;
    if (!mounted) return;
    if (currentUser?.mustResetPassword ?? false) {
      setState(() {
        _token = token;
        _hasAdminAccess = currentUser?.hasAdminAccess ?? false;
        _stage = _GateStage.needsPasswordChange;
      });
      return;
    }
    setState(() {
      _token = token;
      _hasAdminAccess = currentUser?.hasAdminAccess ?? false;
      _stage = _GateStage.ready;
    });
    if (token != null) {
      unawaited(NotificationCoordinator.start(baseUrl: _baseUrl!, token: token));
    }
  }

  Future<void> _onPasswordChanged() async {
    setState(() => _stage = _GateStage.ready);
    if (_baseUrl != null && _token != null) {
      unawaited(NotificationCoordinator.start(baseUrl: _baseUrl!, token: _token!));
    }
  }

  Future<void> _onChangeServer() async {
    if (_baseUrl != null && _token != null) {
      await NotificationCoordinator.stop();
    }
    await AuthService.logout();
    await ModulabsConnection.clear();
    if (!mounted) return;
    setState(() {
      _baseUrl = null;
      _token = null;
      _hasAdminAccess = false;
      _stage = _GateStage.needsUrl;
    });
  }

  Future<void> _onLogout() async {
    if (_baseUrl != null && _token != null) {
      await NotificationCoordinator.stop();
    }
    await AuthService.logout();
    if (!mounted) return;
    setState(() {
      _token = null;
      _hasAdminAccess = false;
      _stage = _GateStage.needsLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _GateStage.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _GateStage.needsUrl:
        return ConnectionSetupPage(initialUrl: _baseUrl, onConnected: _onConnected);
      case _GateStage.needsLogin:
        return LoginPage(
          baseUrl: _baseUrl!,
          onLoggedIn: _onLoggedIn,
          onChangeServer: _onChangeServer,
        );
      case _GateStage.needsPasswordChange:
        return ChangePasswordPage(
          baseUrl: _baseUrl!,
          token: _token!,
          forced: true,
          onDone: _onPasswordChanged,
        );
      case _GateStage.ready:
        return InfrastructureMonitorPage(
          baseUrl: _baseUrl!,
          token: _token!,
          hasAdminAccess: _hasAdminAccess,
          onDisconnect: _onChangeServer,
          onLogout: _onLogout,
        );
    }
  }
}
