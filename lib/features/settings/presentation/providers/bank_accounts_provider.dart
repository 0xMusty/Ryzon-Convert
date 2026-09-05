import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BankAccountItem {
  final String id;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final bool isPrimary;

  const BankAccountItem({
    required this.id,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    this.isPrimary = false,
  });

  factory BankAccountItem.fromJson(Map<String, dynamic> json) {
    return BankAccountItem(
      id: json['id'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      bankCode: json['bank_code'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

final userBankAccountsProvider = FutureProvider<List<BankAccountItem>>((ref) async {
  ref.watch(authProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final res = await Supabase.instance.client
        .from('user_bank_accounts')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List data = res as List? ?? [];
    return data.map((item) => BankAccountItem.fromJson(item)).toList();
  } catch (_) {
    return [];
  }
});
