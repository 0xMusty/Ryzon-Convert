import 'package:equatable/equatable.dart';

class KycEntity extends Equatable {
  final String idType; // 'NIN' or 'BVN'
  final String idNumber;
  final bool isVerified;
  final String tier;
  final DateTime? verifiedAt;

  const KycEntity({
    required this.idType,
    required this.idNumber,
    required this.isVerified,
    required this.tier,
    this.verifiedAt,
  });

  String get nin => idType.toUpperCase() == 'NIN' ? idNumber : '';
  String get bvn => idType.toUpperCase() == 'BVN' ? idNumber : '';

  @override
  List<Object?> get props => [idType, idNumber, isVerified, tier, verifiedAt];
}
