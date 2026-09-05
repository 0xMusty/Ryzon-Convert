import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.phone,
    super.firstName,
    super.lastName,
    super.isKycVerified,
    super.kycTier,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      isKycVerified: json['isKycVerified'] as bool? ?? false,
      kycTier: json['kycTier'] as String? ?? 'Tier 0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'isKycVerified': isKycVerified,
      'kycTier': kycTier,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      phone: entity.phone,
      firstName: entity.firstName,
      lastName: entity.lastName,
      isKycVerified: entity.isKycVerified,
      kycTier: entity.kycTier,
    );
  }
}
