import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'pin_settings_screen.dart';
import '../../../kyc/presentation/screens/kyc_details_screen.dart';
import 'contact_support_screen.dart';
import 'help_faq_screen.dart';
import 'referrals_screen.dart';
import 'select_bank_screen.dart';
import '../providers/bank_accounts_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoSettlement = true;

  void _onLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isKycVerified = user?.isKycVerified ?? false;
    final userName = user != null
        ? '${user.firstName ?? 'Mustapha'} ${user.lastName ?? 'Abubakar'}'
        : 'Mustapha Abubakar';
    final userPhone = user?.phone ?? '+234 903 940 5554';

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

          SafeArea(
            child: Column(
              children: [
                // Header Title with Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(mainNavigationIndexProvider.notifier).state = 0;
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
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
                      ),
                      const Expanded(
                        child: Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Content List
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // User Info Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: AppColors.inputBorder, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    width: 2.0,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 38,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userPhone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // KYC Badge
                              GestureDetector(
                                onTap: () {
                                  if (isKycVerified) {
                                    Navigator.of(context, rootNavigator: true).push(
                                      MaterialPageRoute(
                                        builder: (_) => const KycDetailsScreen(),
                                      ),
                                    );
                                  } else {
                                    context.push('/kyc-info');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isKycVerified
                                        ? AppColors.successBg
                                        : AppColors.warningBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isKycVerified
                                          ? AppColors.success
                                              .withValues(alpha: 0.3)
                                          : AppColors.warning
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isKycVerified
                                            ? Icons.verified_user_rounded
                                            : Icons.shield_outlined,
                                        size: 14,
                                        color: isKycVerified
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isKycVerified
                                            ? 'KYC Verified (Tier 1)'
                                            : 'Unverified (Tier 0)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isKycVerified
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Linked Bank Accounts Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: AppColors.inputBorder, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LINKED BANK ACCOUNTS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Bank Accounts List or Zero State
                              ref.watch(userBankAccountsProvider).when(
                                    data: (banks) {
                                      if (banks.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.account_balance_outlined,
                                                  color: AppColors.primary,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text(
                                                  'No bank account linked yet',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: banks.map((bank) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      bank.bankName.isNotEmpty ? bank.bankName[0] : 'B',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        bank.bankName,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w800,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '•••• ${bank.accountNumber.length > 4 ? bank.accountNumber.substring(bank.accountNumber.length - 4) : bank.accountNumber}',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                    loading: () => const CircularProgressIndicator(),
                                    error: (_, __) => const SizedBox(),
                                  ),

                              const SizedBox(height: 14),
                              const Divider(
                                height: 1,
                                color: AppColors.inputBorder,
                              ),
                              const SizedBox(height: 14),

                              // Add Bank Account Action
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SelectBankScreen(),
                                    ),
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Bank Account',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Settings Menu Options Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: AppColors.inputBorder, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Verification Menu Item
                              _buildMenuItem(
                                icon: Icons.check_rounded,
                                title: 'Verification',
                                badgeWidget: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isKycVerified
                                        ? AppColors.successBg
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isKycVerified ? 'Verified' : 'Unverified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isKycVerified
                                          ? AppColors.success
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  if (isKycVerified) {
                                    Navigator.of(context, rootNavigator: true).push(
                                      MaterialPageRoute(
                                        builder: (_) => const KycDetailsScreen(),
                                      ),
                                    );
                                  } else {
                                    context.push('/kyc-info');
                                  }
                                },
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  color: AppColors.inputBorder),

                              // PIN Settings
                              _buildMenuItem(
                                icon: Icons.lock_outline_rounded,
                                title: 'PIN Settings',
                                subtitle: 'Manage transaction PIN',
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PinSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  color: AppColors.inputBorder),

                              // Auto-Settlement Toggle
                              _buildMenuItem(
                                icon: Icons.account_balance_rounded,
                                title: 'Auto-Settlement to Bank',
                                subtitle: _autoSettlement
                                    ? 'Direct NGN payout on crypto deposit'
                                    : 'Credit converted NGN to wallet balance',
                                onTap: () {
                                  setState(() {
                                    _autoSettlement = !_autoSettlement;
                                  });
                                },
                                badgeWidget: Switch(
                                  value: _autoSettlement,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _autoSettlement = val;
                                    });
                                  },
                                ),
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  color: AppColors.inputBorder),

                              // Referral
                              _buildMenuItem(
                                icon: Icons.card_giftcard_rounded,
                                title: 'Referral',
                                subtitle: 'Earn ₦500 per referral',
                                badgeWidget: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Invite Friends',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ReferralsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  color: AppColors.inputBorder),

                              // Help & FAQ
                              _buildMenuItem(
                                icon: Icons.help_outline_rounded,
                                title: 'Help & FAQ',
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => const HelpFaqScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  color: AppColors.inputBorder),

                              // Contact Support
                              _buildMenuItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'Contact Support',
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ContactSupportScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Soft Red Log Out Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _onLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: CustomBottomNavBar(
      //   currentIndex: _currentNavIndex,
      //   onTap: (index) {
      //     if (index == 0) {
      //       Navigator.of(context).pop();
      //     } else {
      //       setState(() {
      //         _currentNavIndex = index;
      //       });
      //     }
      //   },
      // ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? badgeWidget,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeWidget != null) badgeWidget,
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
