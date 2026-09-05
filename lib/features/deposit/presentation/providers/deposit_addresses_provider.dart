import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/breet_service.dart';

class DepositAddressState {
  final Map<String, String> chainAddresses; // e.g. {'BSC': '0x...', 'ARBITRUM': '0x...'}
  final bool isLoading;
  final String? error;

  const DepositAddressState({
    this.chainAddresses = const {},
    this.isLoading = false,
    this.error,
  });

  DepositAddressState copyWith({
    Map<String, String>? chainAddresses,
    bool? isLoading,
    String? error,
  }) {
    return DepositAddressState(
      chainAddresses: chainAddresses ?? this.chainAddresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DepositAddressesNotifier extends StateNotifier<DepositAddressState> {
  final Ref ref;
  final BreetService _breetService = BreetService();

  DepositAddressesNotifier(this.ref) : super(const DepositAddressState()) {
    fetchAssignedAddresses();
  }

  Future<void> fetchAssignedAddresses() async {
    state = state.copyWith(isLoading: true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, chainAddresses: {});
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('crypto_deposit_addresses')
          .select('chain, address')
          .eq('user_id', user.id);

      final Map<String, String> addressMap = {};
      String? evmAddress;

      for (final row in (res as List? ?? [])) {
        final chain = (row['chain'] as String? ?? '').toUpperCase();
        final addr = row['address'] as String? ?? '';
        if (chain.isNotEmpty && addr.isNotEmpty) {
          addressMap[chain] = addr;
          if (chain == 'BSC' || chain == 'ARBITRUM' || chain == 'PLASMA' || chain == 'EVM') {
            evmAddress ??= addr;
          }
        }
      }

      // Propagate EVM address across all EVM compatible chains
      if (evmAddress != null) {
        addressMap['BSC'] ??= evmAddress;
        addressMap['ARBITRUM'] ??= evmAddress;
        addressMap['PLASMA'] ??= evmAddress;
      }

      state = state.copyWith(isLoading: false, chainAddresses: addressMap);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String?> generateAddressForChain({
    required String chainLabel,
    required String assetId,
    bool autoSettlement = true,
  }) async {
    state = state.copyWith(isLoading: true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, error: 'User unauthenticated');
      return null;
    }

    try {
      final model = await _breetService.generateDepositAddress(
        assetId: assetId,
        label: 'ryzon_user_${user.id.substring(0, 8)}',
        autoSettlement: autoSettlement,
      );

      final newMap = Map<String, String>.from(state.chainAddresses);
      const evmChains = ['BSC', 'ARBITRUM', 'PLASMA'];

      if (evmChains.contains(chainLabel.toUpperCase())) {
        for (final evmChain in evmChains) {
          newMap[evmChain] = model.walletAddress;
        }
      } else {
        newMap[chainLabel.toUpperCase()] = model.walletAddress;
      }

      state = state.copyWith(isLoading: false, chainAddresses: newMap);
      return model.walletAddress;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final depositAddressesProvider =
    StateNotifierProvider<DepositAddressesNotifier, DepositAddressState>((ref) {
  ref.watch(authProvider);
  return DepositAddressesNotifier(ref);
});
