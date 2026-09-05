import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ryzon/core/theme/app_colors.dart';
import 'package:ryzon/core/theme/app_typography.dart';
import 'package:ryzon/shared/layouts/scaffold_with_appbar.dart';
import 'package:ryzon/shared/widgets/buttons/primary_button.dart';
import 'package:ryzon/shared/widgets/status/loading_indicator.dart';

class DepositStatusScreen extends StatelessWidget {
  const DepositStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAppBar(
      title: 'Deposit Tracker',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            const LoadingIndicator(
              message: 'Listening for incoming blockchain transaction...',
              size: 48,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildStatusRow('Step 1', 'Deposit Detected', true),
                  const Divider(height: 24),
                  _buildStatusRow('Step 2', 'Block Confirmations', false),
                  const Divider(height: 24),
                  _buildStatusRow('Step 3', 'Auto-Converting to Naira', false),
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Back to Dashboard',
              onPressed: () {
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

  Widget _buildStatusRow(String step, String title, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isDone ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step, style: AppTypography.bodySmall),
            Text(title, style: AppTypography.heading3),
          ],
        ),
      ],
    );
  }
}
