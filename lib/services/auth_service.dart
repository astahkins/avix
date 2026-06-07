import 'dart:math';
import 'dart:typed_data';

import 'package:blake2b/blake2b.dart';
import 'package:ed25519/ed25519.dart';
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
    String nickname, [
    String? publicKey,
  ]) async {
    final privateKey = _generatePrivateKey();
    final generatedPublicKey = Ed25519.publickey(_blake2bHashFunc, privateKey);

    final privateKeyHex = _bytesToHex(privateKey);
    final publicKeyHex = publicKey ?? _bytesToHex(generatedPublicKey);

    final response = await _apiClient.post(
      '/auth/register/verify',
      {
        'email': email,
        'code': code,
        'nickname': nickname,
        'publicKey': publicKeyHex,
      },
    );

    if (response is! Map<String, dynamic> ||
        response['access_token'] is! String) {
      throw const ApiException('Invalid auth response');
    }

    await _storageService.savePrivateKey(privateKeyHex);
    await _storageService.savePublicKey(publicKeyHex);
    await _storageService.saveNickname(nickname);
    await _secureStorage.write(
      key: _authTokenStorageKey,
      value: response['access_token'] as String,
    );

    return User(
      nickname: nickname,
      publicKey: publicKeyHex,
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

  Uint8List _generatePrivateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    return Uint8List.fromList(bytes);
  }

  Uint8List _blake2bHashFunc(Uint8List message) {
    final bytes = Uint8List(64);
    final hash = Blake2b(512);

    hash.update(message, 0, message.length);
    hash.digest(bytes, 0);

    return bytes;
  }

  String _bytesToHex(Uint8List bytes) {
    const hexChars = '0123456789abcdef';
    final buffer = StringBuffer();

    for (final byte in bytes) {
      buffer.write(hexChars[(byte >> 4) & 0x0f]);
      buffer.write(hexChars[byte & 0x0f]);
    }

    return buffer.toString();
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
