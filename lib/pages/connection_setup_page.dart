import 'package:flutter/material.dart';

import '../models/saved_modulab.dart';
import '../services/modulabs_connection.dart';
import '../theme/app_theme.dart';

/// First screen shown to the user: either lets them pick a previously saved
/// Modulabs instance, or enter the address (and a custom name) of a new one,
/// validating that it is actually reachable before letting the rest of the
/// app use it.
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
  late final TextEditingController _nameController;
  bool _testing = false;
  bool _loadingSaved = true;
  bool _showForm = false;
  String? _errorMessage;
  List<SavedModulab> _saved = const [];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _nameController = TextEditingController();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await ModulabsConnection.getSavedConnections();
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _showForm = saved.isEmpty;
      _loadingSaved = false;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _connectTo(String baseUrl) async {
    setState(() {
      _testing = true;
      _errorMessage = null;
    });

    final result = await ModulabsConnection.testConnection(baseUrl);

    if (!mounted) return;
    setState(() => _testing = false);

    if (result != ConnectionResult.success) {
      setState(() => _errorMessage = _errorFor(result));
      return;
    }

    await ModulabsConnection.saveUrl(baseUrl);
    widget.onConnected(baseUrl);
  }

  Future<void> _connectSaved(SavedModulab connection) async {
    await _connectTo(connection.baseUrl);
    if (!mounted) return;
    // Only mark it active if the connection actually succeeded - re-check
    // instead of trusting _connectTo blindly since it may have failed above.
    final saved = await ModulabsConnection.getSavedUrl();
    if (saved == connection.baseUrl) {
      await ModulabsConnection.setActiveConnectionId(connection.id);
    }
  }

  Future<void> _connectNew() async {
    final normalized = ModulabsConnection.normalize(_urlController.text);
    if (normalized == null) {
      setState(() => _errorMessage = 'Invalid address. Example: http://192.168.1.10:8080');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Give this Modulabs a name so you can find it again.');
      return;
    }

    setState(() {
      _testing = true;
      _errorMessage = null;
    });

    final result = await ModulabsConnection.testConnection(normalized);

    if (!mounted) return;
    setState(() => _testing = false);

    if (result != ConnectionResult.success) {
      setState(() => _errorMessage = _errorFor(result));
      return;
    }

    final connection = await ModulabsConnection.addConnection(name: name, baseUrl: normalized);
    await ModulabsConnection.saveUrl(normalized);
    await ModulabsConnection.setActiveConnectionId(connection.id);
    if (!mounted) return;
    widget.onConnected(normalized);
  }

  String _errorFor(ConnectionResult result) {
    switch (result) {
      case ConnectionResult.success:
        return '';
      case ConnectionResult.unreachable:
        return 'Unable to reach this address. Check that Modulabs is running and reachable from this device.';
      case ConnectionResult.notModulabs:
        return 'This address responded but does not look like a Modulabs instance.';
      case ConnectionResult.invalidUrl:
        return 'Invalid address. Example: http://192.168.1.10:8080';
    }
  }

  Future<void> _renameSaved(SavedModulab connection) async {
    final controller = TextEditingController(text: connection.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.trim().isEmpty) return;
    await ModulabsConnection.renameConnection(connection.id, newName.trim());
    await _loadSaved();
  }

  Future<void> _deleteSaved(SavedModulab connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forget this Modulabs?'),
        content: Text('"${connection.name}" will be removed from your saved list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ModulabsConnection.removeConnection(connection.id);
    await _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Modulabs'),
        centerTitle: true,
        leading: _showForm && _saved.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _showForm = false;
                  _errorMessage = null;
                }),
              )
            : null,
      ),
      body: SafeArea(
        child: _loadingSaved
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: _showForm ? _buildForm() : _buildSavedList(),
              ),
      ),
    );
  }

  Widget _buildSavedList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const ModulabsWordmark(fontSize: 26),
        const SizedBox(height: 8),
        Text(
          'Choose a Modulabs to connect to.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.faint(0.6)),
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: _saved.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final connection = _saved[index];
              return Card(
                color: AppColors.base100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.faint(0.05)),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: const Icon(Icons.dns_outlined, color: AppColors.primary),
                  title: Text(connection.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    connection.baseUrl,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.faint(0.5)),
                  ),
                  onTap: _testing ? null : () => _connectSaved(connection),
                  trailing: _testing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'rename') _renameSaved(connection);
                            if (value == 'delete') _deleteSaved(connection);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: Text('Rename')),
                            PopupMenuItem(value: 'delete', child: Text('Forget')),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _testing
                ? null
                : () => setState(() {
                      _showForm = true;
                      _errorMessage = null;
                      _urlController.clear();
                      _nameController.clear();
                    }),
            icon: const Icon(Icons.add),
            label: const Text('Add a Modulabs'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.dns_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        const ModulabsWordmark(fontSize: 30),
        const SizedBox(height: 8),
        Text(
          'Enter your Modulabs server address to start monitoring.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.faint(0.6)),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          enabled: !_testing,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Home, Office...',
            prefixIcon: Icon(Icons.label_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          enabled: !_testing,
          onSubmitted: (_) => _connectNew(),
          decoration: const InputDecoration(
            labelText: 'Modulabs address',
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
            onPressed: _testing ? null : _connectNew,
            child: _testing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryContent,
                    ),
                  )
                : const Text('Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
