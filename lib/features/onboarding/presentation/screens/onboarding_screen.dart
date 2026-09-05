import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ryzon/core/theme/app_colors.dart';
import 'package:ryzon/core/theme/app_typography.dart';
import 'package:ryzon/shared/widgets/buttons/primary_button.dart';
import 'package:ryzon/shared/widgets/buttons/secondary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.bolt_rounded,
      'title': 'Convert Crypto to Naira in Seconds',
      'description':
          'Deposit USDT or USDC, auto-convert at live market rates, and withdraw directly to any Nigerian bank account.',
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Zero Manual Hassle',
      'description':
          'Dedicated EVM deposit addresses on Arbitrum, BSC, and Plasma networks with automatic transaction processing.',
    },
    {
      'icon': Icons.payments_rounded,
      'title': 'Fixed ₦20 Withdrawal Fee',
      'description':
          'Transparent, fair pricing with zero hidden charges when transferring your Naira payouts to any bank.',
    },
    {
      'icon': Icons.shield_rounded,
      'title': 'Bank-Grade Security',
      'description':
          'Protected with 4-digit transaction PIN, encrypted authentication, and top-tier financial security standards.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        )
                            .animate()
                            .scale(duration: 400.ms, curve: Curves.easeOutBack)
                            .fade(duration: 300.ms),
                        const SizedBox(height: 36),
                        Text(
                          slide['title'] as String,
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),
                        const SizedBox(height: 12),
                        Text(
                          slide['description'] as String,
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ).animate().slideY(begin: 0.3, end: 0, duration: 450.ms).fade(),
                      ],
                    );
                  },
                ),
              ),
              SmoothPageIndicator(
                controller: _pageController,
                count: _slides.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: AppColors.primary,
                  dotColor: Color(0xFFCBD5E1),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Create Account',
                onPressed: () => context.push('/signup'),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Sign In',
                onPressed: () => context.push('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
