import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_numeric_keypad.dart';
import '../../../../shared/widgets/pin_code_field.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isPasswordReset;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _otp = '';
  int _secondsRemaining = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_otp.length < 6) {
      setState(() {
        _otp += digit;
      });
    }
  }

  void _onBackspace() {
    if (_otp.isNotEmpty) {
      setState(() {
        _otp = _otp.substring(0, _otp.length - 1);
      });
    }
  }

  void _onSubmit() async {
    if (_otp.length == 6) {
      final purpose = widget.isPasswordReset ? 'PASSWORD_RESET' : 'REGISTRATION';
      final isValid = await ref.read(authProvider.notifier).verifyOtp(
            email: widget.email,
            otpCode: _otp,
            purpose: purpose,
          );

      if (mounted) {
        if (isValid) {
          if (widget.isPasswordReset) {
            context.push('/reset-password');
          } else {
            context.push('/create-pin');
          }
        } else {
          final error = ref.read(authProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error ?? 'Invalid or expired OTP code',
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter 6-digit code',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _resendCode() async {
    final purpose = widget.isPasswordReset ? 'PASSWORD_RESET' : 'REGISTRATION';
    final sent = await ref.read(authProvider.notifier).sendOtp(
          email: widget.email,
          purpose: purpose,
        );

    if (mounted) {
      if (sent) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'A new 6-digit verification code has been sent!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'Failed to resend code',
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

  String _maskEmail(String email) {
    if (email.isEmpty) return 'musta***@gmail.com';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) return '$name***@$domain';
    return '${name.substring(0, 5)}***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final maskedEmail = _maskEmail(widget.email);

    return AuthBackground(
      showBackButton: true,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Header Title with Envelope Emoji
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.isPasswordReset
                            ? 'Reset code '
                            : 'Verify your email ',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        '✉️',
                        style: TextStyle(fontSize: 28),
                      ),
                    ],
                  ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fade(),
                  const SizedBox(height: 8),

                  // Subtitle with Masked Email
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'We sent a 6-digit code to '),
                        TextSpan(
                          text: maskedEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.3, end: 0, duration: 450.ms).fade(),
                  const SizedBox(height: 36),

                  // 6-Digit OTP Code Input Box Row
                  PinCodeField(
                    pin: _otp,
                    length: 6,
                    isObscured: false,
                  ).animate().slideY(begin: 0.4, end: 0, duration: 500.ms).fade(),
                  const SizedBox(height: 28),

                  // Resend Code Countdown Timer / Link
                  Center(
                    child: _secondsRemaining > 0
                        ? RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'Resend code in '),
                                TextSpan(
                                  text:
                                      '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: authState.isLoading ? null : _resendCode,
                            child: const Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ).animate().slideY(begin: 0.45, end: 0, duration: 550.ms).fade(),
                ],
              ),
            ),
          ),

          // Custom Numeric Keypad with Blue Submit Arrow
          CustomNumericKeypad(
            onDigitPressed: _onKeyPress,
            onBackspacePressed: _onBackspace,
            onSubmitPressed: _onSubmit,
            showSubmitButton: true,
          ).animate().slideY(begin: 0.5, end: 0, duration: 600.ms).fade(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
