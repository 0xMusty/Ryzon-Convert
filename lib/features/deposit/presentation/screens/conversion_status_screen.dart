import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';

class ConversionStatusScreen extends StatefulWidget {
  const ConversionStatusScreen({super.key});

  @override
  State<ConversionStatusScreen> createState() => _ConversionStatusScreenState();
}

class _ConversionStatusScreenState extends State<ConversionStatusScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/deposit/conversion-complete');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Text(
              'Conversion Status',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Process Tracker Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.inputBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Process Tracker',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('⚙️', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Step 1: Crypto Received (Completed)
                  _buildStepItem(
                    isDone: true,
                    isActive: false,
                    title: 'Crypto Received',
                    subtitle: '30 USDT received successfully',
                    icon: Icons.check,
                    iconBgColor: AppColors.successBg,
                    iconColor: AppColors.success,
                  ),
                  _buildConnector(isDone: true),

                  // Step 2: Converting to Naira (Active)
                  _buildStepItem(
                    isDone: false,
                    isActive: true,
                    title: 'Converting to Naira',
                    subtitle: 'Exchanging at live rate ₦1,380/USDT',
                    icon: Icons.sync,
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                  ),
                  _buildConnector(isDone: false),

                  // Step 3: Naira Credited (Pending)
                  _buildStepItem(
                    isDone: false,
                    isActive: false,
                    title: 'Naira Credited',
                    subtitle: '₦45,000.00 to your Naira wallet',
                    icon: Icons.circle,
                    iconBgColor: const Color(0xFFF1F5F9),
                    iconColor: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Current Exchange Rate Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD0E1FD),
                  width: 1.5,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT EXCHANGE RATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1 USDT = ₦1,380.00',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timer & Progress Indicator
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  '~2 minutes remaining',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                value: 0.65,
                minHeight: 8,
                backgroundColor: Color(0xFFE2E8F0),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required bool isDone,
    required bool isActive,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isActive ? 20 : 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDone || isActive
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? const Color(0xFFD97706)
                      : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isDone}) {
    return Container(
      margin: const EdgeInsets.only(left: 18, top: 4, bottom: 4),
      width: 2,
      height: 24,
      color: isDone ? AppColors.success : AppColors.inputBorder,
    );
  }
}
