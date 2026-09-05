import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';

enum KycStatusType { verifying, success, pending, rejected }

class KycStatusScreen extends StatefulWidget {
  final KycStatusType statusType;
  final String? errorMessage;

  const KycStatusScreen({
    super.key,
    this.statusType = KycStatusType.success,
    this.errorMessage,
  });

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  late KycStatusType _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.statusType;

    if (_currentStatus == KycStatusType.verifying) {
      // Transition verifying state to success after 2.5s simulation in Sandbox
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _currentStatus = KycStatusType.success;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),

            // Badge Icon with Package Animations
            _buildBadgeIcon(),
            const SizedBox(height: 28),

            // Title with Fade In & Slide animation
            Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ).animate(key: ValueKey(_currentStatus)).fadeIn().slideY(begin: 0.2, end: 0.0),
            const SizedBox(height: 10),

            // Subtitle / Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ).animate(key: ValueKey('sub_$_currentStatus')).fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            // Info Card with smooth entrance
            _buildInfoCard().animate(key: ValueKey('card_$_currentStatus')).fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

            const Spacer(),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon() {
    switch (_currentStatus) {
      case KycStatusType.verifying:
        return Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.search_rounded,
              size: 52,
              color: AppColors.primary,
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 900.ms)
            .elevation(end: 12);

      case KycStatusType.success:
        return Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              size: 56,
              color: AppColors.success,
            ),
          ),
        )
            .animate()
            .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.elasticOut)
            .shake(duration: 400.ms, hz: 2);

      case KycStatusType.pending:
        return Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              width: 2.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 52,
              color: Color(0xFFD97706),
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .rotate(begin: -0.05, end: 0.05, duration: 1200.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1200.ms);

      case KycStatusType.rejected:
        return Container(
          width: 105,
          height: 105,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              width: 2.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.close_rounded,
              size: 56,
              color: Color(0xFFEF4444),
            ),
          ),
        )
            .animate()
            .shake(duration: 500.ms, hz: 4)
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 300.ms);
    }
  }

  String get _title {
    switch (_currentStatus) {
      case KycStatusType.verifying:
        return 'Verifying Identity...';
      case KycStatusType.success:
        return 'Verification Successful!';
      case KycStatusType.pending:
        return 'Verification Under Review';
      case KycStatusType.rejected:
        return 'Verification Failed';
    }
  }

  String get _subtitle {
    switch (_currentStatus) {
      case KycStatusType.verifying:
        return 'Checking your NIN & BVN records with NIMC and NIBSS databases.';
      case KycStatusType.success:
        return 'Your Tier 1 KYC is complete. Your daily withdrawal limit is now ₦500,000.00.';
      case KycStatusType.pending:
        return 'Your submission is undergoing manual compliance verification. We will notify you shortly.';
      case KycStatusType.rejected:
        return widget.errorMessage ??
            'Your NIN or BVN record could not be verified. Please double-check your credentials and retry.';
    }
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow('KYC Level', 'Tier 1 Verification'),
          const Divider(height: 24, color: AppColors.inputBorder),
          _buildRow('Daily Limit', '₦500,000.00 / day'),
          const Divider(height: 24, color: AppColors.inputBorder),
          _buildRow(
            'Status',
            _currentStatus == KycStatusType.success
                ? 'Verified'
                : _currentStatus == KycStatusType.pending
                    ? 'Under Review'
                    : _currentStatus == KycStatusType.rejected
                        ? 'Failed'
                        : 'Verifying',
            textColor: _currentStatus == KycStatusType.success
                ? AppColors.success
                : _currentStatus == KycStatusType.rejected
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_currentStatus == KycStatusType.verifying) {
      return const SizedBox.shrink();
    }

    if (_currentStatus == KycStatusType.rejected) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => context.go('/kyc'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Retry Verification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
          }
          context.go('/home');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.35),
        ),
        child: const Text(
          'Continue to Wallet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
