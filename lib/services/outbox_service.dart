import 'package:hive/hive.dart';

import '../models/outbox_message.dart';

class OutboxService {
  static const String _boxName = 'outbox';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<OutboxMessage>(_boxName);
    }
  }

  Future<void> addMessage(OutboxMessage message) async {
    final box = Hive.box<OutboxMessage>(_boxName);
    await box.put(message.id, message);
  }

  List<OutboxMessage> getAllMessages() {
    final box = Hive.box<OutboxMessage>(_boxName);
    final messages = box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
  }

  Future<void> removeMessage(String id) async {
    final box = Hive.box<OutboxMessage>(_boxName);
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = Hive.box<OutboxMessage>(_boxName);
    await box.clear();
  }
}
