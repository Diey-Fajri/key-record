import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/auth_service.dart';
import '../../services/app_update_service.dart';
import '../../services/key_repository.dart';
import '../login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _githubOwner = 'dieyfajri';
  static const String _githubRepository = 'key_record';

  final TextEditingController _usernameController = TextEditingController();
  late final AppUpdateService _appUpdateService;
  bool _saving = false;
  bool _refreshing = false;
  bool _checkingUpdate = false;
  bool _loadingVersion = true;
  DateTime? _lastSyncAt;
  String _appVersion = '-';
  String _visibleUsername = '-';

  @override
  void initState() {
    super.initState();
    _appUpdateService = AppUpdateService(
      owner: _githubOwner,
      repository: _githubRepository,
    );
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
                    TextFormField(
                      initialValue: AuthService.activeEmail.isEmpty ? '-' : AuthService.activeEmail,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.alternate_email),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
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
                                setState(() => _visibleUsername = username);
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
                      label: const Text('Save Username'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
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
                    Text(
                      'Current Username: $_visibleUsername',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
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
                    OutlinedButton.icon(
                      onPressed: _refreshing
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _refreshing = true);
                              try {
                                final connected = await KeyRecordRepository.refreshAllFromFirestore();
                                if (!mounted) return;
                                setState(() => _lastSyncAt = DateTime.now());
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      connected
                                          ? 'Synced latest data from Firestore.'
                                          : 'Firebase not connected. Showing local data.',
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Sync failed: $error')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _refreshing = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.refresh),
                      label: Text(_refreshing ? 'Refreshing...' : 'Refresh'),
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

      if (!result.isUpdateAvailable) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Your app is up to date.')),
        );
        return;
      }

      await _showUpdateDialog(result);
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

  Future<void> _showUpdateDialog(UpdateCheckResult result) async {
    var downloading = false;
    var progressText = 'Preparing download...';

    await showDialog<void>(
      context: context,
      barrierDismissible: !downloading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Available'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current version: ${result.currentVersion}'),
                    const SizedBox(height: 6),
                    Text('Latest version: ${result.latestVersion}'),
                    const SizedBox(height: 12),
                    Text(
                      'Release notes:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E5E8)),
                      ),
                      child: Text(
                        result.release.body.trim().isEmpty
                            ? 'No release notes provided.'
                            : result.release.body.trim(),
                      ),
                    ),
                    if (downloading) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(progressText)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: downloading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Later'),
                ),
                FilledButton(
                  onPressed: downloading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          setDialogState(() {
                            downloading = true;
                            progressText = 'Starting download...';
                          });
                          try {
                            await _appUpdateService.downloadAndInstallApk(
                              result.release,
                              onReceiveProgress: (received, total) {
                                if (total <= 0) {
                                  return;
                                }
                                final percent = ((received / total) * 100).clamp(0, 100).toStringAsFixed(0);
                                setDialogState(() {
                                  progressText = 'Downloading... $percent%';
                                });
                              },
                            );
                            if (!mounted) return;
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('APK downloaded. Continue installation from the installer screen.'),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() => downloading = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Update failed: $error')),
                            );
                          }
                        },
                  child: const Text('Update Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
