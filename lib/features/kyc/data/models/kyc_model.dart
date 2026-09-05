import '../../domain/entities/kyc_entity.dart';

class KycModel extends KycEntity {
  const KycModel({
    required super.idType,
    required super.idNumber,
    required super.isVerified,
    required super.tier,
    super.verifiedAt,
  });

  factory KycModel.fromJson(Map<String, dynamic> json) {
    final String idType = json['idType'] as String? ?? (json['nin'] != null && (json['nin'] as String).isNotEmpty ? 'NIN' : 'BVN');
    final String idNumber = json['idNumber'] as String? ?? (json['nin'] as String? ?? json['bvn'] as String? ?? '');

    return KycModel(
      idType: idType,
      idNumber: idNumber,
      isVerified: json['isVerified'] as bool? ?? false,
      tier: json['tier'] as String? ?? 'Tier 1',
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idType': idType,
      'idNumber': idNumber,
      'nin': nin,
      'bvn': bvn,
      'isVerified': isVerified,
      'tier': tier,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
}
