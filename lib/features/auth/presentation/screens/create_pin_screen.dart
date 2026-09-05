import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_numeric_keypad.dart';
import '../../../../shared/widgets/pin_code_field.dart';
import '../providers/auth_provider.dart';
import 'auth_success_screen.dart';

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  bool _isConfirmStep = false;
  String _pin = '';
  String _createdPin = '';

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
      });

      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _handlePinComplete();
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _handlePinComplete() async {
    if (!_isConfirmStep) {
      setState(() {
        _createdPin = _pin;
        _pin = '';
        _isConfirmStep = true;
      });
    } else {
      if (_pin == _createdPin) {
        String userId = ref.read(authProvider).user?.id ?? '';
        if (userId.isEmpty) {
          try {
            userId = Supabase.instance.client.auth.currentUser?.id ?? '';
          } catch (_) {}
        }
        final success = await ref.read(authProvider.notifier).setPin(
              userId: userId,
              pinCode: _pin,
            );

        if (mounted) {
          if (success) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const AuthSuccessScreen(
                  title: 'PIN Created!',
                  subtitle:
                      'Your transaction PIN has been set successfully. You can now securely authorize transactions.',
                  buttonText: 'Go to Homepage',
                ),
              ),
            );
          } else {
            final error = ref.read(authProvider).errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error ?? 'Failed to set PIN')),
            );
            setState(() {
              _pin = '';
            });
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match. Try again.')),
        );
        setState(() {
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      onBackPressed: () {
        if (_isConfirmStep) {
          setState(() {
            _isConfirmStep = false;
            _pin = '';
          });
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConfirmStep ? 'Confirm PIN' : 'Create PIN',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConfirmStep
                        ? 'Re-enter your 4-digit PIN to confirm.'
                        : 'Set a 4-digit transaction PIN to secure your withdrawals and conversions.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  PinCodeField(
                    pin: _pin,
                    length: 4,
                    isObscured: true,
                  ),
                ],
              ),
            ),
          ),

          CustomNumericKeypad(
            onDigitPressed: _onKeyPress,
            onBackspacePressed: _onBackspace,
            showSubmitButton: false,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
