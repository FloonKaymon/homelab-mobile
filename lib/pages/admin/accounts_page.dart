import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../../models/signup_request.dart';
import '../../services/admin_accounts_service.dart';
import '../../services/admin_roles_service.dart';
import '../../services/api_exceptions.dart';
import '../../theme/app_theme.dart';

/// Admin screen for account validation: lists pending signup requests and
/// lets the admin approve or reject them (`/api/admin/signup-requests/**`).
class AccountsPage extends StatefulWidget {
  final String baseUrl;
  final String token;
  final VoidCallback onLogout;

  const AccountsPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.onLogout,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<SignupRequest> _requests = [];
  List<Role> _roles = [];
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
      final requests = await AdminAccountsService.fetchSignupRequests(widget.baseUrl, widget.token);
      final roles = await AdminRolesService.fetchRoles(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _requests = requests.where((r) => r.status == 'PENDING').toList();
        _roles = roles;
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

  Future<void> _reject(SignupRequest request) async {
    setState(() => _processingIds.add(request.id));
    try {
      await AdminAccountsService.reject(widget.baseUrl, widget.token, request.id);
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

  /// A role must be picked before the backend will approve the request (the
  /// resulting account can't be left roleless), so this opens a picker
  /// first instead of approving directly.
  Future<void> _approve(SignupRequest request) async {
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No role is defined on this Modulabs yet. Create one from the web interface before approving.')),
      );
      return;
    }

    final selected = <int>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Approve ${request.name.isNotEmpty ? request.name : request.email}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'At least one role must be assigned to create the account.',
                  style: TextStyle(fontSize: 12, color: AppColors.faint(0.6)),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _roles.map((role) {
                      return CheckboxListTile(
                        value: selected.contains(role.id),
                        title: Text(role.name),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selected.add(role.id);
                            } else {
                              selected.remove(role.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selected.isEmpty ? null : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(request.id));
    try {
      await AdminAccountsService.approve(widget.baseUrl, widget.token, request.id, selected.toList());
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account approved.')),
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

  Widget _buildRequestCard(SignupRequest request) {
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
            Text(request.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(request.email, style: TextStyle(fontSize: 13, color: AppColors.faint(0.6))),
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
