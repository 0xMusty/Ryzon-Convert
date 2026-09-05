import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> saveUserSession(UserModel user);
  Future<UserModel?> getUserSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const _tokenKey = 'ryzon_auth_token';
  static const _userKey = 'ryzon_user_data';

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> saveAuthToken(String token) async {
    try {
      await secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      throw CacheException(message: 'Failed to write token: $e');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return await secureStorage.read(key: _tokenKey);
    } catch (e) {
      throw CacheException(message: 'Failed to read token: $e');
    }
  }

  @override
  Future<void> saveUserSession(UserModel user) async {
    try {
      final jsonString = jsonEncode(user.toJson());
      await secureStorage.write(key: _userKey, value: jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to save session: $e');
    }
  }

  @override
  Future<UserModel?> getUserSession() async {
    try {
      final jsonString = await secureStorage.read(key: _userKey);
      if (jsonString == null) return null;
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await secureStorage.delete(key: _tokenKey);
      await secureStorage.delete(key: _userKey);
    } catch (e) {
      throw CacheException(message: 'Failed to clear session: $e');
    }
  }
}
