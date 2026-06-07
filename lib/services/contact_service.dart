import 'package:hive/hive.dart';

import '../models/contact.dart';

class ContactService {
  static const String _boxName = 'contacts';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Contact>(_boxName);
    }
  }

  Future<void> addContact(Contact contact) async {
    final box = Hive.box<Contact>(_boxName);
    await box.put(contact.publicKey, contact);
  }

  List<Contact> getAllContacts() {
    final box = Hive.box<Contact>(_boxName);
    return box.values.toList();
  }

  Future<void> deleteContact(String publicKey) async {
    final box = Hive.box<Contact>(_boxName);
    await box.delete(publicKey);
  }
}
