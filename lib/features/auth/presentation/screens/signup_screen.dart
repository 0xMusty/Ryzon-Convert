import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      context.push(
        '/signup-details',
        extra: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'referralCode': _referralController.text.trim(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Title with Lightning Emoji
              const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Create account ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFF59E0B),
                    size: 26,
                  ),
                ],
              ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                "Let's get you set up to convert your crypto to Naira instantly.",
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ).animate().slideY(begin: 0.3, end: 0, duration: 450.ms).fade(),
              const SizedBox(height: 28),

              // First Name Input
              CustomTextField(
                label: 'First Name',
                hintText: 'Enter your first name',
                controller: _firstNameController,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter your first name';
                  return null;
                },
              ).animate().slideY(begin: 0.35, end: 0, duration: 400.ms).fade(),
              const SizedBox(height: 20),

              // Last Name Input
              CustomTextField(
                label: 'Last Name',
                hintText: 'Enter your last name',
                controller: _lastNameController,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter your last name';
                  return null;
                },
              ).animate().slideY(begin: 0.4, end: 0, duration: 450.ms).fade(),
              const SizedBox(height: 20),

              // Phone Number Input
              CustomTextField(
                label: 'Phone Number',
                hintText: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter your phone number';
                  return null;
                },
              ).animate().slideY(begin: 0.45, end: 0, duration: 500.ms).fade(),
              const SizedBox(height: 20),

              // Referral Code (Optional) Input
              CustomTextField(
                label: 'Referral Code (Optional)',
                hintText: 'Enter your referral code (If any)',
                controller: _referralController,
              ).animate().slideY(begin: 0.5, end: 0, duration: 550.ms).fade(),
              const SizedBox(height: 36),

              // Primary CTA Button: Continue
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinue,
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
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.55, end: 0, duration: 600.ms).fade(),
              const SizedBox(height: 24),

              // Bottom Link: Already have an account? Log in
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
