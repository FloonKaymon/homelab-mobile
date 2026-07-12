import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Login screen shown once the app is linked to a Modulabs server but no
/// valid session is stored yet.
class LoginPage extends StatefulWidget {
  final String baseUrl;
  final VoidCallback onLoggedIn;
  final VoidCallback onChangeServer;

  const LoginPage({
    super.key,
    required this.baseUrl,
    required this.onLoggedIn,
    required this.onChangeServer,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez renseigner votre email et votre mot de passe.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthService.login(widget.baseUrl, email, password);

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case LoginResult.success:
        widget.onLoggedIn();
        break;
      case LoginResult.invalidCredentials:
        setState(() => _errorMessage = 'Email ou mot de passe incorrect.');
        break;
      case LoginResult.unreachable:
        setState(() => _errorMessage = 'Impossible de joindre le serveur Modulabs.');
        break;
      case LoginResult.error:
        setState(() => _errorMessage = 'Une erreur est survenue. Réessayez.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.lock_outline, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const ModulabsWordmark(fontSize: 28),
              const SizedBox(height: 8),
              Text(
                widget.baseUrl,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.faint(0.5)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                enabled: !_loading,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
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
                  onPressed: _loading ? null : _login,
                  child: _loading
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : widget.onChangeServer,
                child: const Text('Changer de serveur Modulabs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
