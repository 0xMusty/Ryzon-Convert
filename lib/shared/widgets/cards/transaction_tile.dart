import 'package:flutter/material.dart';
import 'package:ryzon/core/theme/app_colors.dart';
import 'package:ryzon/core/theme/app_typography.dart';
import '../status/status_badge.dart';

enum TransactionType { deposit, withdrawal }

class TransactionTile extends StatelessWidget {
  final String title;
  final String dateString;
  final String amountFormatted;
  final TransactionType type;
  final TransactionStatus status;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.title,
    required this.dateString,
    required this.amountFormatted,
    required this.type,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDeposit = type == TransactionType.deposit;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDeposit ? AppColors.successBg : AppColors.infoBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: isDeposit ? AppColors.success : AppColors.info,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.heading3.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateString,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDeposit ? '+' : '-'}$amountFormatted',
                  style: AppTypography.heading3.copyWith(
                    color: isDeposit ? AppColors.success : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
