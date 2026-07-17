import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'admin/accounts_page.dart';
import 'admin/password_resets_page.dart';
import 'admin/roles_page.dart';
import 'admin/system_page.dart';

/// Admin section of the app: account validation (accounts), password reset
/// moderation (resets), role assignment (roles) and system controls
/// (system). Gated on `UserDto.hasAdminAccess` (see `main.dart`) - available to
/// the administrator and to any ADMIN_ACCESS holder. Actions reserved to the
/// real administrator (changing the admin's roles) are refused by the backend.
class AdminPage extends StatelessWidget {
  final String baseUrl;
  final String token;
  final VoidCallback onLogout;

  const AdminPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Administration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.faint(0.5),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Accounts'),
              Tab(text: 'Resets'),
              Tab(text: 'Roles'),
              Tab(text: 'System'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                AccountsPage(baseUrl: baseUrl, token: token, onLogout: onLogout),
                PasswordResetsPage(baseUrl: baseUrl, token: token, onLogout: onLogout),
                RolesPage(baseUrl: baseUrl, token: token, onLogout: onLogout),
                SystemPage(baseUrl: baseUrl, token: token, onLogout: onLogout),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
