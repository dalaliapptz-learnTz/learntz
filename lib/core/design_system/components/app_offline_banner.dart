import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// LearnTZ Design System 2.0 — Canonical Offline & Synchronization Banner
class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({
    required this.isOnline,
    super.key,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.onRetry,
  });

  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isOnline && !isSyncing && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final (bg, border, fg, icon, text) = switch ((isOnline, isSyncing)) {
      (false, _) => (
        LearnTzColors.warningBg,
        LearnTzColors.warningBorder,
        LearnTzColors.warningText,
        Icons.cloud_off_outlined,
        pendingCount > 0
            ? 'Offline Mode — $pendingCount activity changes saved locally'
            : 'Offline Mode — You are browsing cached lessons',
      ),
      (true, true) => (
        LearnTzColors.infoBg,
        LearnTzColors.infoBorder,
        LearnTzColors.infoText,
        Icons.sync_rounded,
        'Syncing offline learning activity with server...',
      ),
      (true, false) => (
        LearnTzColors.primary50,
        LearnTzColors.primary200,
        LearnTzColors.primary700,
        Icons.cloud_upload_outlined,
        '$pendingCount pending changes waiting for sync',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1.0)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LearnTzSpacing.maxContentWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  isSyncing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(fg),
                          ),
                        )
                      : Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: LearnTzTypography.caption.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (!isOnline && onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: fg,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Retry Now'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
