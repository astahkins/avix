import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  Future<({String privateKey, String publicKey})> generateKeyPair() async {
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    return (
      privateKey: bytesToBase64(privateKeyBytes),
      publicKey: bytesToBase64(publicKey.bytes),
    );
  }

  Future<String> deriveSharedSecret(
    String myPrivateKeyBase64,
    String otherPublicKeyBase64,
  ) async {
    final algorithm = X25519();
    final myPrivateKeyBytes = base64ToBytes(myPrivateKeyBase64);
    final otherPublicKeyBytes = base64ToBytes(otherPublicKeyBase64);

    final myKeyPair = await algorithm.newKeyPairFromSeed(myPrivateKeyBytes);
    final otherPublicKey = SimplePublicKey(
      otherPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    final sharedSecretKey = await algorithm.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: otherPublicKey,
    );
    final sharedSecretBytes = await sharedSecretKey.extractBytes();

    return bytesToBase64(sharedSecretBytes);
  }

  Future<String> encryptAES(
    String plaintext,
    String sharedSecretBase64,
  ) async {
    final cipher = AesGcm.with256bits();
    final sharedSecretBytes = base64ToBytes(sharedSecretBase64);
    final secretKey = SecretKey(sharedSecretBytes);
    final nonce = cipher.newNonce();
    final plaintextBytes = utf8.encode(plaintext);

    final sealed = await cipher.encrypt(
      plaintextBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return [
      bytesToBase64(sealed.nonce),
      bytesToBase64(sealed.cipherText),
      bytesToBase64(sealed.mac.bytes),
    ].join(':');
  }

  Future<String> decryptAES(
    String encryptedData,
    String sharedSecretBase64,
  ) async {
    final parts = encryptedData.split(':');

    if (parts.length != 3) {
      throw const FormatException('Invalid encrypted data format');
    }

    final cipher = AesGcm.with256bits();
    final sharedSecretBytes = base64ToBytes(sharedSecretBase64);
    final secretKey = SecretKey(sharedSecretBytes);
    final nonce = base64ToBytes(parts[0]);
    final cipherText = base64ToBytes(parts[1]);
    final mac = Mac(base64ToBytes(parts[2]));
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final decryptedBytes = await cipher.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }

  String bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  List<int> base64ToBytes(String base64) {
    return base64Decode(base64);
  }
}
