import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  static const String _authTokenStorageKey = 'auth_token';

  final ApiClient _apiClient;
  final StorageService _storageService;
  final FlutterSecureStorage _secureStorage;

  AuthService({
    ApiClient? apiClient,
    StorageService? storageService,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? StorageService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> requestVerificationCode(String email) async {
    await _apiClient.post(
      '/auth/register/email',
      {
        'email': email,
      },
    );
  }

  Future<User> register(
    String email,
    String code,
    String nickname,
  ) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    final privateKeyBase64 = base64Encode(privateKeyBytes);
    final publicKeyBase64 = base64Encode(publicKey.bytes);

    final response = await _apiClient.post(
      '/auth/register/verify',
      {
        'email': email,
        'code': code,
        'nickname': nickname,
        'publicKey': publicKeyBase64,
      },
    );

    if (response is! Map<String, dynamic> ||
        response['access_token'] is! String) {
      throw const ApiException('Invalid auth response');
    }

    await _storageService.savePrivateKey(privateKeyBase64);
    await _storageService.savePublicKey(publicKeyBase64);
    await _storageService.saveNickname(nickname);
    await _secureStorage.write(
      key: _authTokenStorageKey,
      value: response['access_token'] as String,
    );

    return User(
      nickname: nickname,
      publicKey: publicKeyBase64,
    );
  }

  Future<String?> getToken() {
    return _secureStorage.read(key: _authTokenStorageKey);
  }

  Future<UserInfo> getMe() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException('Auth token not found');
    }

    final response = await _apiClient.get('/auth/me', token);

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid user response');
    }

    return UserInfo.fromJson(response);
  }
}

class UserInfo {
  final int id;
  final String email;
  final String nickname;
  final String publicKey;

  const UserInfo({
    required this.id,
    required this.email,
    required this.nickname,
    required this.publicKey,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      publicKey: json['public_key'] as String,
    );
  }
}
