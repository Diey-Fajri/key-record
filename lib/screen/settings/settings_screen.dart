import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/auth_service.dart';
import '../../services/app_update_service.dart';
import '../../services/key_repository.dart';
import '../../widget/app_update_dialog.dart';
import '../login/login_screen.dart';
import 'about_screen.dart';
import 'system_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  late final AppUpdateService _appUpdateService;
  bool _saving = false;
  bool _refreshing = false;
  bool _checkingUpdate = false;
  bool _validatingUpdateConfig = false;
  bool _loadingVersion = true;
  bool _editingProfile = false;
  DateTime? _lastSyncAt;
  DateTime? _lastUpdateCheckedAt;
  String _appVersion = '-';
  String _visibleUsername = '-';

  @override
  void initState() {
    super.initState();
    _appUpdateService = AppUpdateService();
    _usernameController.text = AuthService.activeUser;
    _visibleUsername = AuthService.activeUser.trim().isEmpty ? '-' : AuthService.activeUser.trim();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E5E8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (!_editingProfile) ...[
                      Text(
                        'Username: $_visibleUsername',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${AuthService.activeEmail.isEmpty ? '-' : AuthService.activeEmail}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _editingProfile = true;
                            _usernameController.text = _visibleUsername == '-' ? '' : _visibleUsername;
                          });
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ] else ...[
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter username',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final username = _usernameController.text.trim();
                                      if (username.isEmpty) {
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Username cannot be empty.')),
                                        );
                                        return;
                                      }

                                      setState(() => _saving = true);
                                      try {
                                        await AuthService.updateUsername(username);
                                        if (!mounted) return;
                                        setState(() {
                                          _visibleUsername = username;
                                          _editingProfile = false;
                                        });
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Username updated.')),
                                        );
                                      } catch (error) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Update failed: $error')),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _saving = false);
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00695C),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () {
                                      setState(() {
                                        _editingProfile = false;
                                        _usernameController.text = _visibleUsername == '-' ? '' : _visibleUsername;
                                      });
                                    },
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E5E8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Key Record SSC was designed and developed by FAJRI (S17380).\nInitial app release: 2026.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E5E8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Updates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _loadingVersion ? 'Current version: Loading...' : 'Current version: $_appVersion',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Update source: GitHub Release → Firestore metadata',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastUpdateCheckedAt == null
                          ? 'Last checked: Never'
                          : 'Last checked: ${_formatDateTime(_lastUpdateCheckedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: (_checkingUpdate || _loadingVersion) ? null : _checkForUpdates,
                      icon: _checkingUpdate
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.system_update_alt),
                      label: Text(_checkingUpdate ? 'Checking...' : 'Check for Updates'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: (_validatingUpdateConfig || _checkingUpdate)
                          ? null
                          : _validateUpdateConfig,
                      icon: _validatingUpdateConfig
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.rule_folder_outlined),
                      label: Text(
                        _validatingUpdateConfig
                            ? 'Validating config...'
                            : 'Validate Update Config',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E5E8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SettingsActionTile(
                          icon: Icons.info_outline,
                          title: 'About',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _SettingsActionTile(
                          icon: Icons.build_circle_outlined,
                          title: 'System Info',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const SystemInfoScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E5E8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refresh',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _lastSyncAt == null
                          ? 'Last sync: Never'
                          : 'Last sync: ${_formatDateTime(_lastSyncAt!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsActionTile(
                      icon: Icons.refresh,
                      title: _refreshing ? 'Refreshing...' : 'Refresh',
                      onTap: _refreshing
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _refreshing = true);
                              try {
                                await KeyRecordRepository.refreshAllFromFirestore();
                                if (!mounted) return;
                                setState(() => _lastSyncAt = DateTime.now());
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('done refresh')),
                                );
                              } catch (error) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Refresh failed: $error')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _refreshing = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  AuthService.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF263238),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = info.version;
        _loadingVersion = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersion = 'Unknown';
        _loadingVersion = false;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdate = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _appUpdateService.checkForUpdate(currentVersion: _appVersion);
      if (!mounted) return;
      setState(() => _lastUpdateCheckedAt = DateTime.now());

      if (!result.isUpdateAvailable) {
        messenger.showSnackBar(
          const SnackBar(content: Text("You're using the latest version.")),
        );
        return;
      }

      await showAppUpdateDialog(
        context: context,
        result: result,
        appUpdateService: _appUpdateService,
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Update check failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingUpdate = false);
      }
    }
  }

  Future<void> _validateUpdateConfig() async {
    setState(() => _validatingUpdateConfig = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _appUpdateService.validateCurrentUpdateConfig();
      if (!mounted) return;

      if (result.isValid) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Update config valid. Firebase update is ready.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        return;
      }

      final lines = <String>[];
      if (!result.exists) {
        lines.add('- Missing document: app_updates/current');
      }
      if (result.missingFields.isNotEmpty) {
        lines.add('- Missing fields: ${result.missingFields.join(', ')}');
      }
      if (!result.apkUrlResolved) {
        lines.add('- APK URL not resolvable from Firebase Storage');
      }
      for (final error in result.errors) {
        lines.add('- $error');
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Config Issues'),
          content: SingleChildScrollView(
            child: Text(lines.join('\n')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Validation failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _validatingUpdateConfig = false);
      }
    }
  }

}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E5E8)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E3A5F)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF607D8B)),
          ],
        ),
      ),
    );
  }
}
