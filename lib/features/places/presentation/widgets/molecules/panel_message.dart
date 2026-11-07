import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Fills a bottom sheet when there is nothing to list, saying what is happening
/// and what to do about it.
class PanelMessage extends StatelessWidget {
  const PanelMessage({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress) ...[
            const LinearProgressIndicator(
              color: AppColors.blue,
              backgroundColor: AppColors.line,
            ),
            const SizedBox(height: 16),
          ],
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: textTheme.bodyMedium),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.white,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
