import 'dart:async';

import 'package:flutter/material.dart';

import 'pages/connection_setup_page.dart';
import 'pages/infrastructure_monitor_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/homelab_connection.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homelab Monitor',
      theme: buildHomelabTheme(),
      home: const ConnectionGate(),
    );
  }
}

enum _GateStage { loading, needsUrl, needsLogin, ready }

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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final url = await HomelabConnection.getSavedUrl();
    if (url == null) {
      if (!mounted) return;
      setState(() => _stage = _GateStage.needsUrl);
      return;
    }

    final token = await AuthService.getToken();
    if (token != null && await AuthService.verifyToken(url, token)) {
      if (!mounted) return;
      setState(() {
        _baseUrl = url;
        _token = token;
        _stage = _GateStage.ready;
      });
      unawaited(PushService.initialize(baseUrl: url, token: token));
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
    setState(() {
      _token = token;
      _stage = _GateStage.ready;
    });
    if (token != null) {
      unawaited(PushService.initialize(baseUrl: _baseUrl!, token: token));
    }
  }

  Future<void> _onChangeServer() async {
    if (_baseUrl != null && _token != null) {
      await PushService.teardown(_baseUrl!, _token!);
    }
    await AuthService.logout();
    await HomelabConnection.clear();
    if (!mounted) return;
    setState(() {
      _baseUrl = null;
      _token = null;
      _stage = _GateStage.needsUrl;
    });
  }

  Future<void> _onLogout() async {
    if (_baseUrl != null && _token != null) {
      await PushService.teardown(_baseUrl!, _token!);
    }
    await AuthService.logout();
    if (!mounted) return;
    setState(() {
      _token = null;
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
      case _GateStage.ready:
        return InfrastructureMonitorPage(
          baseUrl: _baseUrl!,
          token: _token!,
          onDisconnect: _onChangeServer,
          onLogout: _onLogout,
        );
    }
  }
}
