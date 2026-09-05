import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ryzon/core/constants/app_constants.dart';
import 'package:ryzon/core/theme/app_colors.dart';
import 'package:ryzon/core/theme/app_typography.dart';
import 'package:ryzon/core/utils/currency_formatter.dart';
import 'package:ryzon/shared/layouts/scaffold_with_appbar.dart';
import 'package:ryzon/shared/widgets/buttons/primary_button.dart';

class WithdrawConfirmScreen extends StatelessWidget {
  const WithdrawConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double amount = 50000.0;
    const double fee = AppConstants.flatWithdrawalFee;
    const double totalPayout = amount - fee;

    return ScaffoldWithAppBar(
      title: 'Confirm Withdrawal',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSummaryItem('Withdrawal Amount', CurrencyFormatter.formatNaira(amount)),
                  const Divider(height: 24),
                  _buildSummaryItem('Flat Fee', CurrencyFormatter.formatNaira(fee)),
                  const Divider(height: 24),
                  _buildSummaryItem(
                    'Net Bank Payout',
                    CurrencyFormatter.formatNaira(totalPayout),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bank transfers are irreversible. Verify bank account details before confirming.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Confirm & Transfer',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Withdrawal initiated successfully!')),
                );
                if (Navigator.of(context, rootNavigator: true).canPop()) {
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                }
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? AppTypography.heading3 : AppTypography.bodyMedium),
        Text(
          value,
          style: isBold
              ? AppTypography.heading2.copyWith(color: AppColors.primary)
              : AppTypography.heading3,
        ),
      ],
    );
  }
}
