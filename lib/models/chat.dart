import 'package:hive/hive.dart';

part 'chat.g.dart';

@HiveType(typeId: 1)
class Chat {
  @HiveField(0)
  final String chatId;

  @HiveField(1)
  final String contactPublicKey;

  @HiveField(2)
  final String lastMessage;

  @HiveField(3)
  final DateTime lastMessageTime;

  @HiveField(4)
  final bool isSecret;

  const Chat({
    required this.chatId,
    required this.contactPublicKey,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isSecret,
  });
}
