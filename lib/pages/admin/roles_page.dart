import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../../models/user_dto.dart';
import '../../services/admin_roles_service.dart';
import '../../services/api_exceptions.dart';
import '../../theme/app_theme.dart';

/// Admin screen for role assignment: lists users and lets the admin pick
/// which roles (`/api/admin/roles`) apply to each
/// (`PUT /api/admin/users/{id}/roles`). Enforcement (module access, blocked
/// time windows) happens server-side - this screen only assigns.
class RolesPage extends StatefulWidget {
  final String baseUrl;
  final String token;
  final VoidCallback onLogout;

  const RolesPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.onLogout,
  });

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  List<UserDto> _users = [];
  List<Role> _roles = [];
  bool _loading = true;
  String? _error;

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
      final users = await AdminRolesService.fetchUsers(widget.baseUrl, widget.token);
      final roles = await AdminRolesService.fetchRoles(widget.baseUrl, widget.token);
      if (!mounted) return;
      setState(() {
        _users = users;
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
        _error = 'Unable to load users and roles.';
        _loading = false;
      });
    }
  }

  String _roleName(int id) => _roles
      .firstWhere(
        (r) => r.id == id,
        orElse: () => Role(id: id, name: '#$id', moduleIds: const [], blockedWindows: const []),
      )
      .name;

  Future<void> _editRoles(UserDto user) async {
    // The administrator's roles are off-limits (the backend refuses to change them).
    // The card below is already non-interactive for admins; this guards the path anyway.
    if (user.isAdmin) return;
    final selected = Set<int>.from(user.roleIds);
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(user.name.isNotEmpty ? user.name : user.email),
          content: SizedBox(
            width: double.maxFinite,
            child: _roles.isEmpty
                ? const Text('No role is defined on this Modulabs.')
                : ListView(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      await AdminRolesService.assignRoles(widget.baseUrl, widget.token, user.id, result.toList());
      if (!mounted) return;
      setState(() {
        _users = _users
            .map((u) => u.id == user.id
                ? UserDto(
                    id: u.id,
                    email: u.email,
                    name: u.name,
                    isAdmin: u.isAdmin,
                    roleIds: result.toList(),
                    mustResetPassword: u.mustResetPassword,
                  )
                : u)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roles updated.')),
      );
    } on UnauthorizedException {
      widget.onLogout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _users.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildUserCard(_users[index]),
      ),
    );
  }

  Widget _buildUserCard(UserDto user) {
    return Card(
      color: AppColors.base100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.faint(0.05)),
      ),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          user.name.isNotEmpty ? user.name : user.email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (user.isAdmin)
                Chip(
                  label: const Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                )
              else if (user.roleIds.isEmpty)
                Text('No role', style: TextStyle(fontSize: 12, color: AppColors.faint(0.4)))
              else
                ...user.roleIds.map((id) => Chip(
                      label: Text(_roleName(id), style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    )),
            ],
          ),
        ),
        // The administrator's roles can't be changed, so their card offers no edit action.
        trailing: user.isAdmin ? null : const Icon(Icons.edit_outlined),
        onTap: user.isAdmin ? null : () => _editRoles(user),
      ),
    );
  }
}
