import 'package:flutter/material.dart';

import '../services/app_update_service.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required UpdateCheckResult result,
  required AppUpdateService appUpdateService,
}) async {
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
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() {
                          downloading = true;
                          progressText = 'Starting download...';
                        });
                        try {
                          await appUpdateService.downloadAndInstallApk(
                            result.release,
                            onReceiveProgress: (received, total) {
                              if (total <= 0) {
                                return;
                              }
                              final percent =
                                  ((received / total) * 100).clamp(0, 100).toStringAsFixed(0);
                              setDialogState(() {
                                progressText = 'Downloading... $percent%';
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
          );
        },
      );
    },
  );
}
