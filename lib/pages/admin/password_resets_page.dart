import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../models/password_reset_request.dart';
import '../../services/admin_password_reset_service.dart';
import '../../services/api_exceptions.dart';
import '../../theme/app_theme.dart';

/// Admin screen for moderating self-service password reset requests
/// (`/api/admin/password-reset-requests/**`): approving issues a one-time
/// temporary password, shown once so the admin can relay it to the user.
class PasswordResetsPage extends StatefulWidget {
  final String baseUrl;
  final String token;
  final VoidCallback onLogout;

  const PasswordResetsPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.onLogout,
  });

  @override
  State<PasswordResetsPage> createState() => _PasswordResetsPageState();
}

class _PasswordResetsPageState extends State<PasswordResetsPage> {
  List<PasswordResetRequest> _requests = [];
  bool _loading = true;
  String? _error;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await AdminPasswordResetService.fetchRequests(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _requests = requests.where((r) => r.status == 'PENDING').toList();
        _loading = false;
      });
    } on UnauthorizedException {
      widget.onLogout();
    } on ForbiddenException {
      if (!mounted) return;
      setState(() {
        _error = 'Access restricted to administrators.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load pending requests.';
        _loading = false;
      });
    }
  }

  Future<void> _reject(PasswordResetRequest request) async {
    setState(() => _processingIds.add(request.id));
    try {
      await AdminPasswordResetService.reject(widget.baseUrl, widget.token, request.id);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected.')),
      );
    } on UnauthorizedException {
      widget.onLogout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  Future<void> _approve(PasswordResetRequest request) async {
    setState(() => _processingIds.add(request.id));
    try {
      final temporaryPassword = await AdminPasswordResetService.approve(widget.baseUrl, widget.token, request.id);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      await _showTemporaryPasswordDialog(request.email, temporaryPassword);
    } on UnauthorizedException {
      widget.onLogout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  Future<void> _showTemporaryPasswordDialog(String email, String temporaryPassword) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Temporary password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One-time use for $email. It will not be shown again: relay it now.',
              style: TextStyle(fontSize: 13, color: AppColors.faint(0.7)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.base300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                temporaryPassword,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: temporaryPassword));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Copied.')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.faint(0.4)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(
                child: Text('No pending requests.', style: TextStyle(color: AppColors.faint(0.4))),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
      ),
    );
  }

  Widget _buildRequestCard(PasswordResetRequest request) {
    final busy = _processingIds.contains(request.id);
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
            Text(request.email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _reject(request),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => _approve(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.successContent,
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.successContent),
                          )
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
