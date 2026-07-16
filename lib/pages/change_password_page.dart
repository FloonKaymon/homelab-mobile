import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Self-service password change (`PUT /api/auth/password`).
///
/// Used in two contexts:
/// - [forced] = true: shown right after logging in with a one-time temporary
///   password (`UserDto.mustResetPassword`), blocking the rest of the app
///   until a new password is set. No "current password" field, since the
///   login itself already proved identity (mirrors the backend's
///   `!user.mustResetPassword` check in AuthController.updatePassword).
/// - [forced] = false: reachable from Settings at any time, requires the
///   current password and can be dismissed.
class ChangePasswordPage extends StatefulWidget {
  final String baseUrl;
  final String token;
  final bool forced;
  final VoidCallback onDone;

  const ChangePasswordPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.forced,
    required this.onDone,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPassword = _newController.text;
    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'The password must be at least 8 characters long.');
      return;
    }
    if (newPassword != _confirmController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (!widget.forced && _currentController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your current password.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthService.updatePassword(
      widget.baseUrl,
      widget.token,
      currentPassword: widget.forced ? null : _currentController.text,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case UpdatePasswordResult.success:
        widget.onDone();
        break;
      case UpdatePasswordResult.wrongCurrentPassword:
        setState(() => _errorMessage = 'Incorrect current password.');
        break;
      case UpdatePasswordResult.unauthorized:
        setState(() => _errorMessage = 'Session expired, please sign in again.');
        break;
      case UpdatePasswordResult.unreachable:
        setState(() => _errorMessage = 'Unable to reach the Modulabs server.');
        break;
      case UpdatePasswordResult.error:
        setState(() => _errorMessage = 'Something went wrong. Please try again.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.forced
          ? null
          : AppBar(title: const Text('Change Password'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.key_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                widget.forced ? 'New password required' : 'Change password',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              if (widget.forced) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You are signed in with a one-time temporary password. '
                          'Set a new password to continue.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.faint(0.85)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (!widget.forced) ...[
                TextField(
                  controller: _currentController,
                  obscureText: true,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _newController,
                obscureText: true,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  helperText: 'Minimum 8 characters',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: true,
                enabled: !_loading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.key_outlined),
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
                      : const Text('Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (!widget.forced) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
