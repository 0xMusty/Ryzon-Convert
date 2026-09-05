import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String phone;
  final String? firstName;
  final String? lastName;
  final bool isKycVerified;
  final String kycTier;

  const UserEntity({
    required this.id,
    required this.email,
    required this.phone,
    this.firstName,
    this.lastName,
    this.isKycVerified = false,
    this.kycTier = 'Tier 0',
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    bool? isKycVerified,
    String? kycTier,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      kycTier: kycTier ?? this.kycTier,
    );
  }

  @override
  List<Object?> get props => [id, email, phone, firstName, lastName, isKycVerified, kycTier];
}
