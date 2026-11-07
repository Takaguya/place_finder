import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// A coloured dot and a line of text saying whether a place is open.
class OpenStatus extends StatelessWidget {
  const OpenStatus({
    super.key,
    required this.isOpen,
    required this.text,
    this.textColor,
  });

  final bool isOpen;
  final String text;

  /// Overrides the status colour, for backgrounds where it would be too faint.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOpen ? AppColors.open : AppColors.closed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor ?? statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
