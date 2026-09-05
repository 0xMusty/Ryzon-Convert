import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../providers/kyc_provider.dart';
import 'kyc_hosted_webview_screen.dart';
import 'kyc_status_screen.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedIdType = 'NIN'; // 'NIN' or 'BVN'
  final _idNumberController = TextEditingController(text: '12345678901');

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  void _onSubmitKycPressed() async {
    final session = await ref.read(kycProvider.notifier).startNinjaHostedSession(
          idType: _selectedIdType,
          idNumber: '12345678901',
        );

    if (!mounted) return;

    final kycUrl = session?['url'] ?? session?['hosted_url'];

    if (session == null || kycUrl == null) {
      final kycState = ref.read(kycProvider);
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => KycStatusScreen(
            statusType: KycStatusType.rejected,
            errorMessage: kycState.errorMessage ?? 'Failed to generate Ninja Hosted KYC link.',
          ),
        ),
      );
      return;
    }

    // Launch Ninja Hosted KYC Link in In-App WebView per spec
    final resultStatus = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        builder: (_) => KycHostedWebViewScreen(
          kycUrl: kycUrl,
          sessionToken: session['token'],
          idType: _selectedIdType,
        ),
      ),
    );

    if (mounted) {
      if (resultStatus == 'verified' || resultStatus == 'completed') {
        await ref.read(kycProvider.notifier).submitTier1Kyc(
              idType: _selectedIdType,
              idNumber: '12345678901',
            );
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const KycStatusScreen(
                statusType: KycStatusType.success,
              ),
            ),
          );
        }
      } else if (resultStatus == 'review') {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => const KycStatusScreen(
              statusType: KycStatusType.pending,
            ),
          ),
        );
      } else {
        final kycState = ref.read(kycProvider);
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => KycStatusScreen(
              statusType: KycStatusType.rejected,
              errorMessage: kycState.errorMessage ?? 'Ninja KYC verification session was not completed.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);
    final isNin = _selectedIdType == 'NIN';

    return AuthBackground(
      showBackButton: true,
      onBackPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/settings');
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identity Verification',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select your ID type below to launch the official Ninja Verification Portal.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Security Callout Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Powered by Ninja Identity Verification. Enter details directly in the secure widget.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ID Type Segmented Switcher
              const Text(
                'Select Verification Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedIdType != 'NIN') {
                            setState(() {
                              _selectedIdType = 'NIN';
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isNin ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'National ID (NIN)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isNin ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedIdType != 'BVN') {
                            setState(() {
                              _selectedIdType = 'BVN';
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isNin ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Bank Number (BVN)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: !isNin ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (kycState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kycState.errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Submit Primary CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: kycState.isLoading ? null : _onSubmitKycPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: kycState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Start Ninja ${isNin ? 'NIN' : 'BVN'} Verification',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
