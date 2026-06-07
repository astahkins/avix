import 'dart:math';

import 'package:hive/hive.dart';

import '../models/chat.dart';

class ChatService {
  static const String _boxName = 'chats';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Chat>(_boxName);
    }
  }

  List<Chat> getAllChats() {
    final box = Hive.box<Chat>(_boxName);
    return box.values.toList();
  }

  Chat? getChat(String chatId) {
    final box = Hive.box<Chat>(_boxName);
    return box.get(chatId);
  }

  Future<Chat> getOrCreateChat(
    String contactPublicKey, {
    bool isSecret = false,
  }) async {
    final box = Hive.box<Chat>(_boxName);

    for (final chat in box.values) {
      if (chat.contactPublicKey == contactPublicKey &&
          chat.isSecret == isSecret) {
        return chat;
      }
    }

    final chat = Chat(
      chatId: _generateChatId(),
      contactPublicKey: contactPublicKey,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      isSecret: isSecret,
    );

    await box.put(chat.chatId, chat);

    return chat;
  }

  Future<Chat> getOrCreateChatByPublicKey(
    String publicKey, {
    bool isSecret = false,
  }) {
    return getOrCreateChat(
      publicKey,
      isSecret: isSecret,
    );
  }

  Future<void> updateLastMessage(
    String chatId,
    String message,
    DateTime time,
  ) async {
    final box = Hive.box<Chat>(_boxName);
    final chat = box.get(chatId);

    if (chat == null) {
      return;
    }

    final updatedChat = Chat(
      chatId: chat.chatId,
      contactPublicKey: chat.contactPublicKey,
      lastMessage: message,
      lastMessageTime: time,
      isSecret: chat.isSecret,
    );

    await box.put(chatId, updatedChat);
  }

  Future<void> deleteChat(String chatId) async {
    final box = Hive.box<Chat>(_boxName);
    await box.delete(chatId);
  }

  String _generateChatId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map(_byteToHex).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String _byteToHex(int byte) {
    return byte.toRadixString(16).padLeft(2, '0');
  }
}
