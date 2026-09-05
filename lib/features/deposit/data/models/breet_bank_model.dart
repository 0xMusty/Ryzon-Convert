class BreetBankModel {
  final String id;
  final String name;
  final String code;
  final String currency;

  BreetBankModel({
    required this.id,
    required this.name,
    required this.code,
    required this.currency,
  });

  factory BreetBankModel.fromJson(Map<String, dynamic> json) {
    return BreetBankModel(
      id: json['id'] ?? json['_id'] ?? json['bankId'] ?? '',
      name: json['name'] ?? json['bankName'] ?? '',
      code: json['code'] ?? json['bankCode'] ?? '',
      currency: json['currency'] ?? 'NGN',
    );
  }
}

class BreetVerifiedAccountModel {
  final String accountNumber;
  final String accountName;
  final String bankId;
  final String bankName;

  BreetVerifiedAccountModel({
    required this.accountNumber,
    required this.accountName,
    required this.bankId,
    required this.bankName,
  });

  factory BreetVerifiedAccountModel.fromJson(Map<String, dynamic> json) {
    return BreetVerifiedAccountModel(
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? json['account_name'] ?? '',
      bankId: json['bankId'] ?? json['bank_id'] ?? '',
      bankName: json['bankName'] ?? json['bank_name'] ?? '',
    );
  }
}
