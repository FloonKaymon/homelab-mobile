import 'package:flutter/material.dart';

import '../services/modulabs_connection.dart';
import '../theme/app_theme.dart';

/// First screen shown to the user: lets them enter the URL of their
/// Modulabs instance and validates that it is actually reachable before
/// letting the rest of the app use it.
class ConnectionSetupPage extends StatefulWidget {
  final String? initialUrl;
  final void Function(String baseUrl) onConnected;

  const ConnectionSetupPage({
    super.key,
    this.initialUrl,
    required this.onConnected,
  });

  @override
  State<ConnectionSetupPage> createState() => _ConnectionSetupPageState();
}

class _ConnectionSetupPageState extends State<ConnectionSetupPage> {
  late final TextEditingController _urlController;
  bool _testing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final normalized = ModulabsConnection.normalize(_urlController.text);
    if (normalized == null) {
      setState(() => _errorMessage = 'Adresse invalide. Exemple : http://192.168.1.10:8080');
      return;
    }

    setState(() {
      _testing = true;
      _errorMessage = null;
    });

    final result = await ModulabsConnection.testConnection(normalized);

    if (!mounted) return;

    setState(() => _testing = false);

    switch (result) {
      case ConnectionResult.success:
        await ModulabsConnection.saveUrl(normalized);
        if (!mounted) return;
        widget.onConnected(normalized);
        break;
      case ConnectionResult.unreachable:
        setState(() => _errorMessage =
            'Impossible de joindre cette adresse. Vérifiez que Modulabs est démarré et accessible depuis cet appareil.');
        break;
      case ConnectionResult.notModulabs:
        setState(() => _errorMessage =
            'Cette adresse a répondu mais ne semble pas être une instance Modulabs.');
        break;
      case ConnectionResult.invalidUrl:
        setState(() => _errorMessage = 'Adresse invalide. Exemple : http://192.168.1.10:8080');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion à Modulabs'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.dns_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const ModulabsWordmark(fontSize: 30),
              const SizedBox(height: 8),
              Text(
                "Entrez l'adresse de votre serveur Modulabs pour commencer le suivi.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.faint(0.6)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                enabled: !_testing,
                onSubmitted: (_) => _connect(),
                decoration: const InputDecoration(
                  labelText: 'Adresse de Modulabs',
                  hintText: 'http://192.168.1.10:8080',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _testing ? null : _connect,
                  child: _testing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryContent,
                          ),
                        )
                      : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
