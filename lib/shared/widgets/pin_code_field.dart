import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PinCodeField extends StatefulWidget {
  final String pin;
  final int length;
  final bool isObscured;
  final bool showForgotPin;
  final VoidCallback? onForgotPinTap;

  const PinCodeField({
    super.key,
    required this.pin,
    this.length = 4,
    this.isObscured = false,
    this.showForgotPin = false,
    this.onForgotPinTap,
  });

  @override
  State<PinCodeField> createState() => _PinCodeFieldState();
}

class _PinCodeFieldState extends State<PinCodeField>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _cursorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final hasValue = index < widget.pin.length;
            final isCurrent = index == widget.pin.length;
            final value = hasValue ? widget.pin[index] : '';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.symmetric(
                  horizontal: widget.length == 6 ? 4 : 8),
              width: widget.length == 6 ? 46 : 58,
              height: widget.length == 6 ? 56 : 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary
                      : (hasValue
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : const Color(0xFFE2E8F0)),
                  width: isCurrent ? 2.0 : (hasValue ? 1.5 : 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: isCurrent ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: _buildBoxContent(hasValue, isCurrent, value),
              ),
            );
          }),
        ),
        if (widget.showForgotPin && widget.onForgotPinTap != null) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: widget.onForgotPinTap,
            child: const Text(
              'Forgot PIN?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBoxContent(bool hasValue, bool isCurrent, String value) {
    // Filled dot for obscured entry
    if (widget.isObscured && hasValue) {
      return Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      );
    }

    // Blinking cursor bar for active (empty) box
    if (isCurrent && !hasValue) {
      return AnimatedBuilder(
        animation: _cursorOpacity,
        builder: (_, __) => Opacity(
          opacity: _cursorOpacity.value,
          child: Container(
            width: 2,
            height: widget.length == 6 ? 24 : 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    }

    // Plain digit for non-obscured entry
    return Text(
      value,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}
