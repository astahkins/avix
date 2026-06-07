import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final SyncService _syncService = SyncService();

  late Future<List<Chat>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _chatsFuture = _syncAndLoadChats();
  }

  Future<List<Chat>> _loadChats() async {
    await _chatService.init();

    final chats = _chatService.getAllChats()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return chats;
  }

  Future<List<Chat>> _syncAndLoadChats() async {
    await _syncService.syncAll();
    return _loadChats();
  }

  Future<void> _refreshChats() async {
    setState(() {
      _chatsFuture = _syncAndLoadChats();
    });

    await _chatsFuture;
  }

  void _openContactsScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const ContactsScreen(),
          ),
        )
        .then((_) async => _refreshChats());
  }

  void _openChatScreen(Chat chat) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            // TODO: Later replace this placeholder with ChatScreen.
            builder: (context) => Scaffold(
              backgroundColor: AvixColors.background,
              appBar: AppBar(
                backgroundColor: AvixColors.background,
                foregroundColor: AvixColors.text,
                title: Text(_shortPublicKey(chat.contactPublicKey)),
              ),
              body: const Center(
                child: Text(
                  'Экран чата (заглушка)',
                  style: TextStyle(
                    color: AvixColors.text,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        )
        .then((_) async => _refreshChats());
  }

  String _shortPublicKey(String publicKey) {
    if (publicKey.length <= 8) {
      return publicKey;
    }

    return '${publicKey.substring(0, 8)}...';
  }

  String _shortMessage(String message) {
    if (message.length <= 50) {
      return message;
    }

    return '${message.substring(0, 50)}...';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;

    if (isToday) {
      final hours = time.hour.toString().padLeft(2, '0');
      final minutes = time.minute.toString().padLeft(2, '0');

      return '$hours:$minutes';
    }

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');

    return '$day.$month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvixColors.background,
      appBar: AppBar(
        backgroundColor: AvixColors.background,
        foregroundColor: AvixColors.text,
        title: const Text('Avix'),
        actions: [
          IconButton(
            onPressed: _openContactsScreen,
            icon: const Icon(Icons.contacts),
          ),
        ],
      ),
      body: FutureBuilder<List<Chat>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AvixColors.accent,
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return RefreshIndicator(
              color: AvixColors.accent,
              backgroundColor: AvixColors.background,
              onRefresh: _refreshChats,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 360,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Нет чатов. Добавьте контакт и начните диалог.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AvixColors.text,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AvixColors.accent,
            backgroundColor: AvixColors.background,
            onRefresh: _refreshChats,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final title = _shortPublicKey(chat.contactPublicKey);
                final subtitle = chat.lastMessage.isEmpty
                    ? 'Нет сообщений'
                    : _shortMessage(chat.lastMessage);

                return ListTile(
                  onTap: () => _openChatScreen(chat),
                  leading: const CircleAvatar(
                    backgroundColor: AvixColors.accent,
                    foregroundColor: AvixColors.text,
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      color: AvixColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Text(
                    _formatTime(chat.lastMessageTime),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
