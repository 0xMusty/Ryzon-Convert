import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ryzon/app/router.dart';
import 'package:ryzon/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:ryzon/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ryzon/features/auth/presentation/screens/login_screen.dart';
import 'package:ryzon/features/auth/presentation/screens/signup_screen.dart';
import 'package:ryzon/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ryzon/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:ryzon/features/auth/presentation/screens/enter_pin_screen.dart';
import 'package:ryzon/features/wallet/presentation/screens/home_screen.dart';
import 'package:ryzon/features/wallet/presentation/screens/notifications_screen.dart';
import 'package:ryzon/features/deposit/presentation/screens/deposit_screen.dart';
import 'package:ryzon/features/withdrawal/presentation/screens/withdraw_screen.dart';
import 'package:ryzon/features/withdrawal/presentation/screens/withdraw_confirm_screen.dart';
import 'package:ryzon/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:ryzon/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:ryzon/features/transactions/presentation/screens/statement_export_screen.dart';
import 'package:ryzon/features/settings/presentation/screens/settings_screen.dart';
import 'package:ryzon/features/settings/presentation/screens/select_bank_screen.dart';
import 'package:ryzon/features/auth/presentation/providers/auth_provider.dart';
import 'package:ryzon/features/auth/domain/entities/user_entity.dart';
import 'package:ryzon/features/kyc/presentation/screens/kyc_screen.dart';

class MockVerifiedAuthNotifier extends AuthNotifier {
  MockVerifiedAuthNotifier(super.ref, {bool isKycVerified = true}) {
    state = AuthState(
      user: UserEntity(
        id: '1',
        email: 'test@example.com',
        phone: '08012345678',
        isKycVerified: isKycVerified,
        kycTier: isKycVerified ? 'Tier 1' : 'Tier 0',
      ),
    );
  }

  @override
  Future<bool> verifyPin({required String userId, required String pinCode}) async {
    return true;
  }

  @override
  Future<void> checkSession() async {}
}

Widget createTestApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
    ),
  );
}

Widget createRouterApp({String initialLocation = '/', bool isKycVerified = true}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: AppRouter.router.configuration.routes,
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => MockVerifiedAuthNotifier(ref, isKycVerified: isKycVerified)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Onboarding Buttons Test', () {
    testWidgets('OnboardingScreen Create Account button navigates to signup', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/onboarding'));
      await tester.pump();

      expect(find.byType(OnboardingScreen), findsOneWidget);

      final createAccountBtn = find.text('Create Account');
      expect(createAccountBtn, findsOneWidget);
      await tester.tap(createAccountBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('OnboardingScreen Sign In button navigates to LoginScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/onboarding'));
      await tester.pump();

      final signInBtn = find.text('Sign In');
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Auth Buttons & Routing Test', () {
    testWidgets('LoginScreen forgot password button opens ForgotPasswordScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/login'));
      await tester.pump();

      final forgotBtn = find.text('Forgot password?');
      expect(forgotBtn, findsOneWidget);
      await tester.ensureVisible(forgotBtn);
      await tester.tap(forgotBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen displays new password fields and submit button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ResetPasswordScreen()));
      await tester.pump();

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text('Create New Password 🔒'), findsOneWidget);

      final resetBtn = find.text('Reset Password');
      expect(resetBtn, findsOneWidget);
    });

    testWidgets('LoginScreen Sign Up text opens SignupScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/login'));
      await tester.pump();

      final signUpText = find.text('Sign Up');
      expect(signUpText, findsOneWidget);
      await tester.ensureVisible(signUpText);
      await tester.tap(signUpText);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('EnterPinScreen numeric keypad entry navigates to HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/enter-pin'));
      await tester.pump();

      expect(find.byType(EnterPinScreen), findsOneWidget);

      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('3'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('4'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Home Dashboard Buttons & Routing Test', () {
    testWidgets('HomeScreen notification bell button opens NotificationsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pump();

      final bellIcon = find.byIcon(Icons.notifications_none_rounded);
      expect(bellIcon, findsOneWidget);
      await tester.tap(bellIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('HomeScreen user avatar button routes to SettingsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/home'));
      await tester.pump();

      final personIcon = find.byIcon(Icons.person_rounded);
      expect(personIcon, findsOneWidget);
      await tester.tap(personIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('HomeScreen DepositAddressCard QR button routes to DepositScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/home'));
      await tester.pump();

      final qrIcon = find.byIcon(Icons.qr_code_2_rounded);
      expect(qrIcon, findsOneWidget);
      await tester.tap(qrIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DepositScreen), findsOneWidget);
    });

    testWidgets('HomeScreen View all text button routes to TransactionsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/home'));
      await tester.pump();

      final viewAllBtn = find.text('View all');
      expect(viewAllBtn, findsOneWidget);
      await tester.ensureVisible(viewAllBtn);
      await tester.tap(viewAllBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('HomeScreen recent activity tile tap expands inline and opens TransactionDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pump();

      final tile = find.text('USDT → Naira');
      expect(tile, findsOneWidget);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump();

      expect(find.text('500.00 USDT'), findsOneWidget);
      expect(find.text('View Full Page Details'), findsOneWidget);

      final fullDetailsBtn = find.text('View Full Page Details');
      await tester.tap(fullDetailsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailScreen), findsOneWidget);
    });

    testWidgets('HomeScreen Bottom Navigation tabs route correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/home'));
      await tester.pump();

      final depositTab = find.descendant(of: find.byType(CustomBottomNavBar), matching: find.text('Deposit'));
      await tester.tap(depositTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DepositScreen), findsOneWidget);

      final activityTab = find.descendant(of: find.byType(CustomBottomNavBar), matching: find.text('Activity'));
      await tester.tap(activityTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TransactionsScreen), findsOneWidget);

      final profileTab = find.descendant(of: find.byType(CustomBottomNavBar), matching: find.text('Profile'));
      await tester.tap(profileTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Withdrawal Flow Buttons Test', () {
    testWidgets('WithdrawScreen Max button populates input', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const WithdrawScreen()));
      await tester.pump();

      final maxBtn = find.text('MAX');
      expect(maxBtn, findsOneWidget);
      await tester.ensureVisible(maxBtn);
      await tester.tap(maxBtn);
      await tester.pump();

      expect(find.text('1,244,980.00'), findsOneWidget);
    });

    testWidgets('WithdrawScreen Add New Bank Account opens SelectBankScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const WithdrawScreen()));
      await tester.pump();

      final addBankBtn = find.text('Add New Bank Account');
      expect(addBankBtn, findsOneWidget);
      await tester.ensureVisible(addBankBtn);
      await tester.tap(addBankBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SelectBankScreen), findsOneWidget);
    });

    testWidgets('WithdrawScreen primary withdraw button routes to WithdrawConfirmScreen when KYC verified', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(
        const WithdrawScreen(),
        overrides: [
          authProvider.overrideWith((ref) => MockVerifiedAuthNotifier(ref)),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final withdrawBtn = find.widgetWithText(ElevatedButton, 'Withdraw ₦50,000.00');
      expect(withdrawBtn, findsOneWidget);
      await tester.ensureVisible(withdrawBtn);
      await tester.tap(withdrawBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WithdrawConfirmScreen), findsOneWidget);
    });

    testWidgets('WithdrawConfirmScreen Confirm & Transfer routes to HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/withdraw/confirm'));
      await tester.pump();

      final confirmBtn = find.text('Confirm & Transfer');
      expect(confirmBtn, findsOneWidget);
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Deposit Screen Buttons Test', () {
    testWidgets('DepositScreen network tabs switch selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const DepositScreen()));
      await tester.pump();

      final arbitrumTab = find.text('Arbitrum');
      expect(arbitrumTab, findsOneWidget);
      await tester.tap(arbitrumTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SUPPORTED TOKENS ON Arbitrum'), findsOneWidget);
    });
  });

  group('Transactions / Activity Screen Buttons Test', () {
    testWidgets('TransactionsScreen filter tabs filter transactions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const TransactionsScreen()));
      await tester.pump();

      final depositsFilter = find.text('Deposits');
      expect(depositsFilter, findsOneWidget);
      await tester.tap(depositsFilter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final depositTile = find.text('50.00 USDT Deposit');
      expect(depositTile, findsOneWidget);
      await tester.tap(depositTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TransactionDetailScreen), findsOneWidget);
    });

    testWidgets('TransactionsScreen top right icon opens StatementExportScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const TransactionsScreen()));
      await tester.pump();

      final exportIcon = find.byIcon(Icons.file_download_outlined);
      expect(exportIcon, findsOneWidget);
      await tester.tap(exportIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StatementExportScreen), findsOneWidget);
    });

    testWidgets('StatementExportScreen Custom Range opens date range picker', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const StatementExportScreen()));
      await tester.pump();

      final customRangeTile = find.text('Custom Range');
      expect(customRangeTile, findsOneWidget);
      await tester.tap(customRangeTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies date picker dialog opens
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });
  });

  group('Back Buttons Verification Test', () {
    testWidgets('StatementExportScreen back button pops screen safely', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/transactions/export'));
      await tester.pump();

      final backIcon = find.byIcon(Icons.arrow_back);
      expect(backIcon, findsOneWidget);
      await tester.tap(backIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('DepositScreen back button returns to HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/deposit'));
      await tester.pump();

      final backIcon = find.byIcon(Icons.arrow_back);
      expect(backIcon, findsOneWidget);
      await tester.tap(backIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('WithdrawScreen back button returns to HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/withdraw'));
      await tester.pump();

      final backIcon = find.byIcon(Icons.arrow_back);
      expect(backIcon, findsOneWidget);
      await tester.tap(backIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Settings / Profile Screen Buttons Test', () {
    testWidgets('SettingsScreen menu options open appropriate sub-screens', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/settings'));
      await tester.pump();

      final addBankText = find.text('Add Bank Account');
      expect(addBankText, findsOneWidget);
      await tester.ensureVisible(addBankText);
      await tester.tap(addBankText);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SelectBankScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen Log Out button navigates to LoginScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/settings'));
      await tester.pump();

      final logoutBtn = find.text('Log Out');
      expect(logoutBtn, findsOneWidget);
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('KYC Screen Buttons Test', () {
    testWidgets('KycDetailsScreen Verify Identity Now button routes to KycScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRouterApp(initialLocation: '/kyc/details', isKycVerified: false));
      await tester.pump();

      final verifyBtn = find.text('Verify Identity Now');
      expect(verifyBtn, findsOneWidget);
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(KycScreen), findsOneWidget);
    });
  });
}
