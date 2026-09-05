import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class TransactionItem {
  final String id;
  final String reference;
  final String type;
  final String status;
  final String cryptoToken;
  final double cryptoAmount;
  final double nairaAmount;
  final double feeNaira;
  final DateTime createdAt;

  const TransactionItem({
    required this.id,
    required this.reference,
    required this.type,
    required this.status,
    required this.cryptoToken,
    required this.cryptoAmount,
    required this.nairaAmount,
    required this.feeNaira,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      type: json['type'] as String? ?? 'DEPOSIT_CONVERT',
      status: json['status'] as String? ?? 'COMPLETED',
      cryptoToken: json['crypto_token'] as String? ?? 'USDT',
      cryptoAmount: (json['crypto_amount'] as num?)?.toDouble() ?? 0.0,
      nairaAmount: (json['naira_amount'] as num?)?.toDouble() ?? 0.0,
      feeNaira: (json['fee_naira'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

final userTransactionsProvider = FutureProvider<List<TransactionItem>>((ref) async {
  ref.watch(authProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final res = await Supabase.instance.client
        .from('transactions')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List data = res as List? ?? [];
    return data.map((item) => TransactionItem.fromJson(item)).toList();
  } catch (_) {
    return [];
  }
});
