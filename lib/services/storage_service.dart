import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _privateKeyStorageKey = 'avix_private_key';
  static const String _publicKeyStorageKey = 'avix_public_key';
  static const String _nicknameStorageKey = 'avix_nickname';

  final FlutterSecureStorage _secureStorage;

  StorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> savePrivateKey(String key) async {
    await _secureStorage.write(
      key: _privateKeyStorageKey,
      value: key,
    );
  }

  Future<String?> getPrivateKey() {
    return _secureStorage.read(key: _privateKeyStorageKey);
  }

  Future<void> savePublicKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_publicKeyStorageKey, key);
  }

  Future<String?> getPublicKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_publicKeyStorageKey);
  }

  Future<void> saveNickname(String nick) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameStorageKey, nick);
  }

  Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameStorageKey);
  }
}
