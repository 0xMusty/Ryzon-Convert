import 'package:flutter/material.dart';
import 'package:ryzon/core/theme/app_colors.dart';
import 'package:ryzon/core/theme/app_typography.dart';

enum TransactionStatus { completed, processing, failed, pending }

class StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case TransactionStatus.completed:
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'Completed';
        break;
      case TransactionStatus.processing:
      case TransactionStatus.pending:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'Processing';
        break;
      case TransactionStatus.failed:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        label = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
