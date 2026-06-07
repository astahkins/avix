import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 2)
class Message {
  @HiveField(0)
  final String messageId;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool isOutgoing;

  @HiveField(5)
  final bool isDelivered;

  @HiveField(6)
  final bool isSecret;

  @HiveField(7)
  final bool isSynced;

  const Message({
    required this.messageId,
    required this.chatId,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
    required this.isDelivered,
    required this.isSecret,
    this.isSynced = false,
  });
}
