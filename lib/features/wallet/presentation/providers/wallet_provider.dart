import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WalletData {
  final double balanceNgn;
  final String settlementMode;
  final String kycStatus;
  final int kycTier;

  const WalletData({
    this.balanceNgn = 0.0,
    this.settlementMode = 'AUTO_SETTLEMENT',
    this.kycStatus = 'unverified',
    this.kycTier = 0,
  });
}

class WalletNotifier extends StateNotifier<WalletData> {
  final Ref ref;

  WalletNotifier(this.ref) : super(const WalletData()) {
    fetchWalletInfo();
  }

  Future<void> fetchWalletInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('wallet_balance_ngn, settlement_mode, kyc_status, kyc_tier')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null) {
          state = WalletData(
            balanceNgn: (res['wallet_balance_ngn'] as num?)?.toDouble() ?? 0.0,
            settlementMode: res['settlement_mode'] as String? ?? 'AUTO_SETTLEMENT',
            kycStatus: res['kyc_status'] as String? ?? 'unverified',
            kycTier: (res['kyc_tier'] as num?)?.toInt() ?? 0,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> updateSettlementMode(String mode) async {
    state = WalletData(
      balanceNgn: state.balanceNgn,
      settlementMode: mode,
      kycStatus: state.kycStatus,
      kycTier: state.kycTier,
    );
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'settlement_mode': mode})
            .eq('id', user.id);
      }
    } catch (_) {}
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletData>((ref) {
  // Listen to auth status changes to refresh wallet info
  ref.watch(authProvider);
  return WalletNotifier(ref);
});
