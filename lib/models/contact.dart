import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 0)
class Contact {
  @HiveField(0)
  final String nickname;

  @HiveField(1)
  final String publicKey;

  @HiveField(2)
  final DateTime createdAt;

  const Contact({
    required this.nickname,
    required this.publicKey,
    required this.createdAt,
  });
}
