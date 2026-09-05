import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/navigation_provider.dart';

class AuthBackground extends ConsumerWidget {
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AuthBackground({
    super.key,
    required this.child,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundGradientStart,
                    AppColors.background,
                    AppColors.backgroundGradientEnd,
                  ],
                ),
              ),
            ),
          ),

          // Top-Right Pill Outline Decorative Shape
          Positioned(
            top: -20,
            right: -30,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 190,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Left Middle Glow Shape
          Positioned(
            left: -40,
            top: size.height * 0.45,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Right Lower Glow Shape
          Positioned(
            right: -30,
            bottom: size.height * 0.25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  width: 2,
                ),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (leading != null)
                        leading!
                      else if (showBackButton)
                        GestureDetector(
                          onTap: onBackPressed ??
                              () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  ref.read(mainNavigationIndexProvider.notifier).state = 0;
                                  context.go('/home');
                                }
                              },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                      if (actions != null) Row(children: actions!) else const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Main Screen Body
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
