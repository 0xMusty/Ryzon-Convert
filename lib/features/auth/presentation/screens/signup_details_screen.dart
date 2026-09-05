import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class SignupDetailsScreen extends ConsumerStatefulWidget {
  final String firstName;
  final String lastName;
  final String phone;
  final String referralCode;

  const SignupDetailsScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.referralCode,
  });

  @override
  ConsumerState<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends ConsumerState<SignupDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasSpecialOrNum = false;
  bool _hasMixedCase = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordRequirements);
  }

  void _checkPasswordRequirements() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 12;
      _hasSpecialOrNum = RegExp(r'[0-9!@#\$&*~]').hasMatch(text);
      _hasMixedCase = RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Passwords do not match.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final success = await ref.read(authProvider.notifier).signup(
            firstName: widget.firstName,
            lastName: widget.lastName,
            email: _emailController.text.trim(),
            phone: widget.phone,
            password: _passwordController.text,
          );

      if (mounted) {
        if (success) {
          context.push(
            '/otp-verification',
            extra: {'email': _emailController.text.trim()},
          );
        } else {
          final error = ref.read(authProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error ?? 'Signup failed. Please try again.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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

              // Header Title
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

              // Email Address Field
              CustomTextField(
                label: 'Email Address',
                hintText: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter your email address';
                  if (!val.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ).animate().slideY(begin: 0.35, end: 0, duration: 400.ms).fade(),
              const SizedBox(height: 20),

              // Password Field
              CustomTextField(
                label: 'Password',
                hintText: 'Create a strong password',
                controller: _passwordController,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Create a strong password';
                  return null;
                },
              ).animate().slideY(begin: 0.4, end: 0, duration: 450.ms).fade(),
              const SizedBox(height: 20),

              // Confirm Password Field
              CustomTextField(
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                controller: _confirmPasswordController,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Confirm your password';
                  if (val != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ).animate().slideY(begin: 0.45, end: 0, duration: 500.ms).fade(),
              const SizedBox(height: 16),

              // Terms & Condition Disclaimer Text
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(
                      text: "By clicking on continue you confirm that you agree to Ryzon's ",
                    ),
                    TextSpan(
                      text: 'Terms & Condition',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.5, end: 0, duration: 550.ms).fade(),
              const SizedBox(height: 20),

              // REQUIREMENTS Card Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFAECBFA).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC6DBFF),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REQUIREMENTS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildRequirementItem(
                      text: 'At least 12 characters long',
                      isMet: _hasMinLength,
                    ),
                    const SizedBox(height: 10),
                    _buildRequirementItem(
                      text: 'At least one number or special character',
                      isMet: _hasSpecialOrNum,
                    ),
                    const SizedBox(height: 10),
                    _buildRequirementItem(
                      text: 'Mixed uppercase & lowercase letters',
                      isMet: _hasMixedCase,
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.55, end: 0, duration: 600.ms).fade(),
              const SizedBox(height: 32),

              // Primary CTA Button: Create Account
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _onSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate().slideY(begin: 0.6, end: 0, duration: 650.ms).fade(),
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

  Widget _buildRequirementItem({required String text, required bool isMet}) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isMet ? AppColors.primary : AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              isMet ? Icons.check : Icons.square,
              size: isMet ? 13 : 8,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
