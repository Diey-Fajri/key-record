import 'package:flutter/material.dart';

import '../services/app_update_service.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required UpdateCheckResult result,
  required AppUpdateService appUpdateService,
}) async {
  var downloading = false;
  var progressText = 'Preparing download...';
  var progressValue = 0.0;

  await showDialog<void>(
    context: context,
    barrierDismissible: !downloading && !result.isForceUpdate,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return PopScope(
            canPop: !downloading && !result.isForceUpdate,
            child: AlertDialog(
              title: const Text('Update Available'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current version: ${result.currentVersion}'),
                    const SizedBox(height: 6),
                    Text('Latest version: ${result.latestVersion}'),
                    if (result.minimumVersion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Minimum required: ${result.minimumVersion}'),
                    ],
                    if (result.isForceUpdate) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: const Text(
                          'This update is required before continuing.',
                          style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
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
                        result.update.releaseNotes.isEmpty
                            ? 'No release notes provided.'
                            : result.update.releaseNotes,
                      ),
                    ),
                    if (downloading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progressValue <= 0 ? null : progressValue),
                      const SizedBox(height: 8),
                      Text(progressText),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!result.isForceUpdate)
                  TextButton(
                    onPressed: downloading ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Later'),
                  ),
                FilledButton(
                  onPressed: downloading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setDialogState(() {
                            downloading = true;
                            progressText = 'Starting download...';
                            progressValue = 0;
                          });
                          try {
                            await appUpdateService.downloadAndInstallApk(
                              result.update,
                              onReceiveProgress: (received, total) {
                                if (total <= 0) {
                                  setDialogState(() {
                                    progressText = 'Downloading...';
                                    progressValue = 0;
                                  });
                                  return;
                                }
                                final fraction = (received / total).clamp(0.0, 1.0);
                                final percent = (fraction * 100).toStringAsFixed(0);
                                setDialogState(() {
                                  progressText = 'Downloading... $percent%';
                                  progressValue = fraction;
                                });
                              },
                            );
                            if (!context.mounted || !dialogContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('APK downloaded. Continue installation from installer screen.'),
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
            ),
          );
        },
      );
    },
  );
}
