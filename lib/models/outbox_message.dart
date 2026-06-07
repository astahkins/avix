import 'package:hive/hive.dart';

part 'outbox_message.g.dart';

@HiveType(typeId: 3)
class OutboxMessage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final bool isSecret;

  const OutboxMessage({
    required this.id,
    required this.chatId,
    required this.text,
    required this.createdAt,
    required this.isSecret,
  });
}
