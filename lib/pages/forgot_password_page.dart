import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Self-service "small reset" request (`POST /api/auth/password-reset-requests`):
/// an admin must approve it from the web admin panel before a one-time
/// temporary password is issued. Always shows the same generic confirmation
/// regardless of whether the email is registered, matching the backend's
/// anti-enumeration behavior.
class ForgotPasswordPage extends StatefulWidget {
  final String baseUrl;

  const ForgotPasswordPage({super.key, required this.baseUrl});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Invalid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final ok = await AuthService.requestPasswordReset(widget.baseUrl, email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      setState(() => _submitted = true);
    } else {
      setState(() => _errorMessage = 'Unable to reach the Modulabs server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                _submitted ? Icons.mark_email_read_outlined : Icons.mail_outline,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              if (_submitted) ...[
                Text(
                  'Request sent. An administrator must approve it before a temporary password becomes available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.faint(0.75), height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to sign in'),
                  ),
                ),
              ] else ...[
                Text(
                  'Enter your email. An administrator will need to approve the request before you can sign back in with a temporary password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.faint(0.6), height: 1.5),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !_loading,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
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
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryContent,
                            ),
                          )
                        : const Text('Send request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
