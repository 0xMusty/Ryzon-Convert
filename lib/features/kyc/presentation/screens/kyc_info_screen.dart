import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class KycInfoScreen extends StatelessWidget {
  const KycInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Identity Verification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge & Title
              // Container(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFFFFBEB),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(
              //       color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              //     ),
              //   ),
              //   child: const Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(Icons.construction_rounded,
              //           color: Color(0xFFD97706), size: 14),
              //       SizedBox(width: 6),
              //       Text(
              //         'Under Integration',
              //         style: TextStyle(
              //           fontSize: 12,
              //           fontWeight: FontWeight.w700,
              //           color: Color(0xFFD97706),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 16),
              const Text(
                'Verify Your Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Identity verification (KYC) is coming soon. Here is a quick overview of what to expect once live.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Simple Key Info Cards
              _buildInfoTile(
                icon: Icons.checklist_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryLight,
                title: 'Requirements',
                subtitle:
                    'Government-issued ID (NIN, Driver\'s License, or Passport) and a selfie scan.',
              ),
              const SizedBox(height: 16),
              _buildInfoTile(
                icon: Icons.star_rounded,
                iconColor: AppColors.success,
                iconBg: AppColors.successBg,
                title: 'Benefits',
                subtitle:
                    'Higher withdrawal limits, unlocked referral program, and enhanced account security.',
              ),
              const SizedBox(height: 16),
              _buildInfoTile(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBg: const Color(0xFFEDE9FE),
                title: 'Safety & Privacy',
                subtitle:
                    'Your data is encrypted with AES-256 and processed solely for regulatory compliance.',
              ),
              const SizedBox(height: 16),
              _buildInfoTile(
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: AppColors.warningBg,
                title: 'Consent',
                subtitle:
                    'By verifying, you consent to accurate document checks with licensed KYC partners.',
              ),

              const Spacer(),

              // Simple Disabled Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
