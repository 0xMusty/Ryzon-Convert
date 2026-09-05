import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_numeric_keypad.dart';
import '../../../../shared/widgets/modals/forgot_pin_otp_modal.dart';
import '../../../../shared/widgets/pin_code_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PinSettingsScreen extends ConsumerStatefulWidget {
  const PinSettingsScreen({super.key});

  @override
  ConsumerState<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends ConsumerState<PinSettingsScreen> {
  int _step = 0; // 0: Current PIN, 1: New PIN, 2: Confirm New PIN
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String _errorMessage = '';
  bool _isVerifying = false;

  void _onDigitPressed(String digit) {
    if (_isVerifying) return;
    setState(() {
      _errorMessage = '';
      if (_step == 0) {
        if (_currentPin.length < 4) _currentPin += digit;
        if (_currentPin.length == 4) _verifyCurrentPin();
      } else if (_step == 1) {
        if (_newPin.length < 4) _newPin += digit;
        if (_newPin.length == 4) {
          _step = 2;
        }
      } else if (_step == 2) {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _saveNewPin();
      }
    });
  }

  void _onDeletePressed() {
    if (_isVerifying) return;
    setState(() {
      _errorMessage = '';
      if (_step == 0 && _currentPin.isNotEmpty) {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      } else if (_step == 1 && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_step == 2 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  Future<void> _verifyCurrentPin() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    final userId = ref.read(authProvider).user?.id ?? '';
    final isValid = await ref
        .read(authProvider.notifier)
        .verifyPin(userId: userId, pinCode: _currentPin);

    setState(() {
      _isVerifying = false;
    });

    if (isValid) {
      setState(() {
        _step = 1;
      });
    } else {
      setState(() {
        _currentPin = '';
        _errorMessage = ref.read(authProvider).errorMessage ??
            'Incorrect PIN. Please try again.';
      });
    }
  }

  Future<void> _saveNewPin() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _confirmPin = '';
        _errorMessage = 'PINs do not match. Try confirming again.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    final userId = ref.read(authProvider).user?.id ?? '';
    final success = await ref
        .read(authProvider.notifier)
        .setPin(userId: userId, pinCode: _newPin);

    setState(() {
      _isVerifying = false;
    });

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      setState(() {
        _confirmPin = '';
        _errorMessage = ref.read(authProvider).errorMessage ??
            'Failed to update PIN. Please try again.';
      });
    }
  }

  void _showSuccessDialog() {
    final screenContext = context;
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            SizedBox(height: 12),
            Text(
              'PIN Changed Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your 4-digit transaction PIN has been updated successfully in your account database.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // close dialog
                Navigator.of(screenContext).pop(); // go back to Settings
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Enter Current PIN';
      case 1:
        return 'Enter New PIN';
      case 2:
        return 'Confirm New PIN';
      default:
        return 'PIN Settings';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 0:
        return 'Verify your current PIN to change transaction PIN';
      case 1:
        return 'Create a new 4-digit security PIN';
      case 2:
        return 'Re-enter your new 4-digit security PIN';
      default:
        return '';
    }
  }

  String get _activePin {
    switch (_step) {
      case 0:
        return _currentPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      onBackPressed: () {
        if (_step > 0) {
          setState(() {
            _step--;
            _errorMessage = '';
          });
        } else {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/settings');
          }
        }
      },
      child: Column(
        children: [
          Text(
            _title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Reusable 4-digit Pin Display with Forgot PIN option
          PinCodeField(
            pin: _activePin,
            length: 4,
            isObscured: true,
            showForgotPin: _step == 0,
            onForgotPinTap: () {
              ForgotPinOtpModal.show(context);
            },
          ),

          if (_isVerifying) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Reusable Custom Numeric Keypad
          CustomNumericKeypad(
            onDigitPressed: _onDigitPressed,
            onBackspacePressed: _onDeletePressed,
            showSubmitButton: false,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
