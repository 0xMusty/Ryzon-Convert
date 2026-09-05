import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class AddAccountDetailsScreen extends StatefulWidget {
  final String bankName;
  final String bankFullName;
  final Color bankColor;

  const AddAccountDetailsScreen({
    super.key,
    this.bankName = 'GTBank',
    this.bankFullName = 'Guaranty Trust Bank',
    this.bankColor = const Color(0xFFE55B13),
  });

  @override
  State<AddAccountDetailsScreen> createState() =>
      _AddAccountDetailsScreenState();
}

class _AddAccountDetailsScreenState extends State<AddAccountDetailsScreen> {
  final _accountNumberController = TextEditingController();
  final FocusNode _accountFocusNode = FocusNode();
  bool _isAccountVerified = false;
  bool _isVerificationFailed = false;

  @override
  void initState() {
    super.initState();
    _accountNumberController.addListener(_onAccountNumberChanged);
    _accountFocusNode.addListener(() {
      setState(() {});
    });
  }

  void _onAccountNumberChanged() {
    setState(() {
      final isTenDigits = _accountNumberController.text.length == 10;
      _isVerificationFailed = isTenDigits;
      _isAccountVerified = false;
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountFocusNode.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_isAccountVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank account added successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Bank Account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Selected Bank Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.inputBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: widget.bankColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        widget.bankName.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bankName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.bankFullName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SELECTED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Number Input
            CustomTextField(
              label: 'Account Number',
              controller: _accountNumberController,
              focusNode: _accountFocusNode,
              keyboardType: TextInputType.number,
              hintText: 'Enter 10-digit account number',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 1.0,
              ),
              suffixIcon: _isVerificationFailed
                  ? const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(height: 20),

            // Gateway Error Banner (when 10 digits entered)
            if (_isVerificationFailed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'GATEWAY LOOKUP PENDING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Account resolution service is currently pending payment gateway integration. Account details could not be validated.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF991B1B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Continue CTA Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isAccountVerified ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
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
    );
  }
}
