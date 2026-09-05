import 'package:go_router/go_router.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/signup_details_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/create_pin_screen.dart';
import '../features/auth/presentation/screens/enter_pin_screen.dart';
import '../features/auth/presentation/screens/auth_success_screen.dart';
import '../features/kyc/presentation/screens/kyc_screen.dart';
import '../features/kyc/presentation/screens/kyc_info_screen.dart';
import '../features/kyc/presentation/screens/kyc_details_screen.dart';
import '../features/kyc/presentation/screens/kyc_status_screen.dart';
import '../features/wallet/presentation/screens/home_screen.dart';
import '../features/deposit/presentation/screens/deposit_screen.dart';
import '../features/deposit/presentation/screens/deposit_status_screen.dart';
import '../features/deposit/presentation/screens/conversion_status_screen.dart';
import '../features/withdrawal/presentation/screens/withdraw_screen.dart';
import '../features/withdrawal/presentation/screens/withdraw_confirm_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import '../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../features/transactions/presentation/screens/statement_export_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/select_bank_screen.dart';
import '../features/settings/presentation/screens/add_account_details_screen.dart';
import '../features/settings/presentation/screens/pin_settings_screen.dart';
import '../features/settings/presentation/screens/referrals_screen.dart';
import '../features/settings/presentation/screens/help_faq_screen.dart';
import '../features/settings/presentation/screens/contact_support_screen.dart';
import '../features/settings/presentation/screens/live_chat_screen.dart';
import '../shared/layouts/main_navigation_shell.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/signup-details',
        builder: (context, state) {
          final args = state.extra as Map<String, String>? ?? {};
          return SignupDetailsScreen(
            firstName: args['firstName'] ?? '',
            lastName: args['lastName'] ?? '',
            phone: args['phone'] ?? '',
            referralCode: args['referralCode'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) => OtpVerificationScreen(
          email: (state.extra as Map<String, dynamic>?)?['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/create-pin',
        builder: (context, state) => const CreatePinScreen(),
      ),
      GoRoute(
        path: '/enter-pin',
        builder: (context, state) => const EnterPinScreen(),
      ),
      GoRoute(
        path: '/auth-success',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return AuthSuccessScreen(
            title: args?['title'] ?? 'Success!',
            subtitle: args?['subtitle'] ?? 'Your action was completed successfully.',
            buttonText: args?['buttonText'] ?? 'Continue to Dashboard',
          );
        },
      ),
      GoRoute(
        path: '/kyc-info',
        builder: (context, state) => const KycInfoScreen(),
      ),
      GoRoute(
        path: '/kyc',
        builder: (context, state) => const KycScreen(),
        routes: [
          GoRoute(
            path: 'details',
            builder: (context, state) => const KycDetailsScreen(),
          ),
          GoRoute(
            path: 'status',
            builder: (context, state) => const KycStatusScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/withdraw',
        builder: (context, state) => const WithdrawScreen(),
        routes: [
          GoRoute(
            path: 'confirm',
            builder: (context, state) => const WithdrawConfirmScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/deposit/status',
        builder: (context, state) => const DepositStatusScreen(),
      ),
      GoRoute(
        path: '/deposit/conversion-status',
        builder: (context, state) => const ConversionStatusScreen(),
      ),
      GoRoute(
        path: '/transactions/detail',
        builder: (context, state) => const TransactionDetailScreen(),
      ),
      GoRoute(
        path: '/transactions/export',
        builder: (context, state) => const StatementExportScreen(),
      ),
      GoRoute(
        path: '/settings/select-bank',
        builder: (context, state) => const SelectBankScreen(),
      ),
      GoRoute(
        path: '/settings/add-account-details',
        builder: (context, state) => const AddAccountDetailsScreen(),
      ),
      GoRoute(
        path: '/settings/pin-settings',
        builder: (context, state) => const PinSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/referrals',
        builder: (context, state) => const ReferralsScreen(),
      ),
      GoRoute(
        path: '/settings/help-faq',
        builder: (context, state) => const HelpFaqScreen(),
      ),
      GoRoute(
        path: '/settings/contact-support',
        builder: (context, state) => const ContactSupportScreen(),
      ),
      GoRoute(
        path: '/settings/live-chat',
        builder: (context, state) => const LiveChatScreen(),
      ),

      // StatefulShellRoute indexedStack for the 4 main tabs with bottom nav bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/deposit',
                builder: (context, state) => const DepositScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
