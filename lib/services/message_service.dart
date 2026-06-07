import 'dart:math';

import 'package:hive/hive.dart';

import '../models/message.dart';
import '../models/outbox_message.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'contact_service.dart';
import 'crypto_service.dart';
import 'internet_detector.dart';
import 'outbox_service.dart';
import 'storage_service.dart';

class MessageService {
  static const String _boxName = 'messages';

  final ApiClient _apiClient;
  final AuthService _authService;
  final ChatService _chatService;
  final ContactService _contactService;
  final CryptoService _cryptoService;
  final InternetDetector _internetDetector;
  final OutboxService _outboxService;
  final StorageService _storageService;

  MessageService({
    ApiClient? apiClient,
    AuthService? authService,
    ChatService? chatService,
    ContactService? contactService,
    CryptoService? cryptoService,
    InternetDetector? internetDetector,
    OutboxService? outboxService,
    StorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService(),
        _chatService = chatService ?? ChatService(),
        _contactService = contactService ?? ContactService(),
        _cryptoService = cryptoService ?? CryptoService(),
        _internetDetector = internetDetector ?? InternetDetector(),
        _outboxService = outboxService ?? OutboxService(),
        _storageService = storageService ?? StorageService();

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Message>(_boxName);
    }

    await _outboxService.init();
  }

  Future<void> sendMessage(
    String chatId,
    String text,
    bool isSecret,
  ) {
    return sendMessageToServer(chatId, text, isSecret);
  }

  Future<void> sendMessageToServer(
    String chatId,
    String text,
    bool isSecret,
  ) async {
    await init();
    await _chatService.init();
    await _contactService.init();

    final chat = _chatService.getChat(chatId);

    if (chat == null) {
      throw StateError('Chat not found: $chatId');
    }

    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException('Auth token not found');
    }

    final messageId = _generateMessageId();
    final now = DateTime.now();
    final hasInternet = await _internetDetector.hasInternet();
    final outgoingText = await _prepareOutgoingText(
      text: text,
      contactPublicKey: chat.contactPublicKey,
      isSecret: isSecret,
    );

    if (!hasInternet) {
      await _saveToOutbox(
        messageId: messageId,
        chatId: chatId,
        text: outgoingText,
        createdAt: now,
        isSecret: isSecret,
      );

      await addMessage(
        Message(
          messageId: messageId,
          chatId: chatId,
          text: text,
          timestamp: now,
          isOutgoing: true,
          isDelivered: false,
          isSecret: isSecret,
          isSynced: false,
        ),
      );

      print('Интернета нет, сообщение сохранено в outbox');
      return;
    }

    try {
      await _apiClient.post(
        '/messages/send',
        {
          'to_nickname_or_publicKey': chat.contactPublicKey,
          'text': outgoingText,
          'is_secret': isSecret,
        },
        token,
      );

      await addMessage(
        Message(
          messageId: messageId,
          chatId: chatId,
          text: text,
          timestamp: now,
          isOutgoing: true,
          isDelivered: true,
          isSecret: isSecret,
          isSynced: true,
        ),
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      await _saveToOutbox(
        messageId: messageId,
        chatId: chatId,
        text: outgoingText,
        createdAt: now,
        isSecret: isSecret,
      );

      await addMessage(
        Message(
          messageId: messageId,
          chatId: chatId,
          text: text,
          timestamp: now,
          isOutgoing: true,
          isDelivered: false,
          isSecret: isSecret,
          isSynced: false,
        ),
      );

      print('Сообщение сохранено в outbox: $error');
    }
  }

  Future<void> addMessage(Message message) async {
    final box = Hive.box<Message>(_boxName);
    await box.put(message.messageId, message);
  }

  List<Message> getMessagesForChat(String chatId) {
    final box = Hive.box<Message>(_boxName);
    final messages = box.values
        .where((message) => message.chatId == chatId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return messages;
  }

  Future<void> addIncomingMessage(
    String chatId,
    String text,
    bool isSecret,
    DateTime timestamp,
  ) async {
    await init();

    final message = Message(
      messageId: _generateMessageId(),
      chatId: chatId,
      text: text,
      timestamp: timestamp,
      isOutgoing: false,
      isDelivered: true,
      isSecret: isSecret,
      isSynced: true,
    );

    await addMessage(message);
  }

  Future<int> syncMessages() async {
    await init();
    await _chatService.init();
    await _contactService.init();

    final hasInternet = await _internetDetector.hasInternet();

    if (!hasInternet) {
      return 0;
    }

    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException('Auth token not found');
    }

    final response = await _apiClient.get('/messages/unread', token);

    if (response is! List) {
      throw const ApiException('Invalid unread messages response');
    }

    var newMessagesCount = 0;

    for (final item in response) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final messageId = item['id']?.toString();

      if (messageId == null || messageId.isEmpty) {
        continue;
      }

      if (await _messageExists(messageId)) {
        continue;
      }

      final encryptedOrPlainText = item['text']?.toString() ?? '';
      final isSecret = item['is_secret'] == true;
      final timestamp = _parseTimestamp(item['created_at']);
      final contactPublicKey = _contactKeyFromUnreadMessage(item);
      final text = await _prepareIncomingText(
        encryptedOrPlainText: encryptedOrPlainText,
        isSecret: isSecret,
        message: item,
      );
      final chat = await _chatService.getOrCreateChat(
        contactPublicKey,
        isSecret: isSecret,
      );

      await addMessage(
        Message(
          messageId: messageId,
          chatId: chat.chatId,
          text: text,
          timestamp: timestamp,
          isOutgoing: false,
          isDelivered: true,
          isSecret: isSecret,
          isSynced: true,
        ),
      );

      await _chatService.updateLastMessage(
        chat.chatId,
        text,
        timestamp,
      );

      newMessagesCount++;
    }

    return newMessagesCount;
  }

  Future<void> processOutbox() async {
    await init();
    await _chatService.init();

    final hasInternet = await _internetDetector.hasInternet();

    if (!hasInternet) {
      print('Интернета нет, очередь outbox пока не отправляется');
      return;
    }

    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      print('Auth token not found, outbox не отправлен');
      return;
    }

    final outboxMessages = _outboxService.getAllMessages();

    for (final outboxMessage in outboxMessages) {
      try {
        final chat = _chatService.getChat(outboxMessage.chatId);

        if (chat == null) {
          print('Чат не найден для outbox: ${outboxMessage.chatId}');
          continue;
        }

        await _apiClient.post(
          '/messages/send',
          {
            'to_nickname_or_publicKey': chat.contactPublicKey,
            'text': outboxMessage.text,
            'is_secret': outboxMessage.isSecret,
          },
          token,
        );

        await _outboxService.removeMessage(outboxMessage.id);
        await _markMessageSynced(outboxMessage.id);
      } catch (error) {
        print('Не удалось отправить сообщение из outbox: $error');
      }
    }
  }

  Future<void> deleteMessagesForChat(String chatId) async {
    final box = Hive.box<Message>(_boxName);
    final keysToDelete = box.keys.where((key) {
      final message = box.get(key);
      return message?.chatId == chatId;
    }).toList();

    await box.deleteAll(keysToDelete);
  }

  Future<void> _saveToOutbox({
    required String messageId,
    required String chatId,
    required String text,
    required DateTime createdAt,
    required bool isSecret,
  }) async {
    final outboxMessage = OutboxMessage(
      id: messageId,
      chatId: chatId,
      text: text,
      createdAt: createdAt,
      isSecret: isSecret,
    );

    await _outboxService.addMessage(outboxMessage);
  }

  Future<String> _prepareOutgoingText({
    required String text,
    required String contactPublicKey,
    required bool isSecret,
  }) async {
    if (!isSecret) {
      return text;
    }

    final myPrivateKey = await _storageService.getPrivateKey();

    if (myPrivateKey == null || myPrivateKey.isEmpty) {
      throw StateError('Private key not found');
    }

    final otherPublicKey = _getContactPublicKey(contactPublicKey);
    final sharedSecret = await _cryptoService.deriveSharedSecret(
      myPrivateKey,
      otherPublicKey,
    );

    return _cryptoService.encryptAES(text, sharedSecret);
  }

  String _getContactPublicKey(String contactPublicKey) {
    final contacts = _contactService.getAllContacts();

    for (final contact in contacts) {
      if (contact.publicKey == contactPublicKey) {
        return contact.publicKey;
      }
    }

    return contactPublicKey;
  }

  Future<bool> _messageExists(String messageId) async {
    final box = Hive.box<Message>(_boxName);
    return box.containsKey(messageId);
  }

  String _contactKeyFromUnreadMessage(Map<String, dynamic> message) {
    final value = _senderPublicKeyFromUnreadMessage(message) ??
        message['from_nickname'] ??
        message['from_user_id'];

    return value?.toString() ?? 'unknown';
  }

  Future<String> _prepareIncomingText({
    required String encryptedOrPlainText,
    required bool isSecret,
    required Map<String, dynamic> message,
  }) async {
    if (!isSecret) {
      return encryptedOrPlainText;
    }

    final myPrivateKey = await _storageService.getPrivateKey();

    if (myPrivateKey == null || myPrivateKey.isEmpty) {
      throw StateError('Private key not found');
    }

    final senderPublicKey = _senderPublicKeyFromUnreadMessage(message);

    if (senderPublicKey == null || senderPublicKey.isEmpty) {
      throw StateError('Sender public key not found');
    }

    final sharedSecret = await _cryptoService.deriveSharedSecret(
      myPrivateKey,
      senderPublicKey,
    );

    return _cryptoService.decryptAES(encryptedOrPlainText, sharedSecret);
  }

  String? _senderPublicKeyFromUnreadMessage(Map<String, dynamic> message) {
    final directPublicKey = message['from_public_key'] ??
        message['fromPublicKey'] ??
        message['senderPublicKey'] ??
        message['public_key'];

    if (directPublicKey != null && directPublicKey.toString().isNotEmpty) {
      return directPublicKey.toString();
    }

    final fromNickname = message['from_nickname']?.toString();

    if (fromNickname == null || fromNickname.isEmpty) {
      return null;
    }

    final contacts = _contactService.getAllContacts();

    for (final contact in contacts) {
      if (contact.nickname == fromNickname) {
        return contact.publicKey;
      }
    }

    return null;
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  Future<void> _markMessageSynced(String messageId) async {
    final box = Hive.box<Message>(_boxName);
    final message = box.get(messageId);

    if (message == null) {
      return;
    }

    final syncedMessage = Message(
      messageId: message.messageId,
      chatId: message.chatId,
      text: message.text,
      timestamp: message.timestamp,
      isOutgoing: message.isOutgoing,
      isDelivered: true,
      isSecret: message.isSecret,
      isSynced: true,
    );

    await box.put(messageId, syncedMessage);
  }

  String _generateMessageId() {
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
