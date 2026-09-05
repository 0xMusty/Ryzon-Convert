import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ryzon/core/errors/failures.dart';
import 'package:ryzon/features/auth/domain/entities/user_entity.dart';
import 'package:ryzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:ryzon/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> login({required String email, required String password}) async {
    if (email == 'user@ryzon.app' && password == 'password123') {
      return right(const UserEntity(id: 'usr_1', email: 'user@ryzon.app', phone: '08012345678'));
    }
    return left(const ServerFailure('Invalid credentials'));
  }

  @override
  Future<Either<Failure, UserEntity>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return right(UserEntity(id: 'usr_2', email: email, phone: phone, firstName: firstName, lastName: lastName));
  }

  @override
  Future<Either<Failure, void>> logout() async => right(null);

  @override
  Future<Either<Failure, UserEntity?>> getStoredSession() async => right(null);
}

void main() {
  late LoginUseCase loginUseCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockRepository);
  });

  test('should return UserEntity when valid credentials are provided', () async {
    final result = await loginUseCase(const LoginParams(email: 'user@ryzon.app', password: 'password123'));
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should succeed'),
      (user) {
        expect(user.email, 'user@ryzon.app');
        expect(user.id, 'usr_1');
      },
    );
  });

  test('should return ServerFailure when invalid credentials are provided', () async {
    final result = await loginUseCase(const LoginParams(email: 'user@ryzon.app', password: 'wrong'));
    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, const ServerFailure('Invalid credentials')),
      (user) => fail('Should fail'),
    );
  });
}
