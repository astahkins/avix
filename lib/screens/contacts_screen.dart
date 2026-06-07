import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../services/contact_service.dart';
import '../utils/constants.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _contactService = ContactService();

  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    await _contactService.init();

    final contacts = _contactService.getAllContacts();

    if (!mounted) {
      return;
    }

    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  void _openAddContactScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddContactScreen(),
          ),
        )
        .then((_) => _loadContacts());
  }

  String _shortPublicKey(String publicKey) {
    if (publicKey.length <= 8) {
      return publicKey;
    }

    return '${publicKey.substring(0, 8)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvixColors.background,
      appBar: AppBar(
        backgroundColor: AvixColors.background,
        foregroundColor: AvixColors.text,
        title: const Text('Контакты'),
        actions: [
          IconButton(
            onPressed: _openAddContactScreen,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AvixColors.accent,
        ),
      );
    }

    if (_contacts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Нет контактов. Нажмите +, чтобы добавить.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AvixColors.text,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];

        return ListTile(
          onTap: () {},
          title: Text(
            contact.nickname,
            style: const TextStyle(
              color: AvixColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _shortPublicKey(contact.publicKey),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }
}
