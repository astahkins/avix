import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/crypto_service.dart';
import '../services/message_service.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String contactNickname;
  final String contactPublicKey;
  final bool isSecret;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.contactNickname,
    required this.contactPublicKey,
    required this.isSecret,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  CryptoService? _cryptoService;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _ensureCryptoReadyForSecretChat();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    await _messageService.init();

    final messages = _messageService.getMessagesForChat(widget.chatId);

    if (!mounted) {
      return;
    }

    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    if (widget.isSecret && _cryptoService == null) {
      _ensureCryptoReadyForSecretChat();

      if (_cryptoService == null) {
        return;
      }
    }

    setState(() {
      _isSending = true;
    });

    // TODO: Later add real server delivery here. For now Avix stores messages locally.
    await _messageService.sendMessage(
      widget.chatId,
      text,
      widget.isSecret,
    );

    _messageController.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
      _messages = _messageService.getMessagesForChat(widget.chatId);
    });

    _scrollToBottom();
  }

  void _ensureCryptoReadyForSecretChat() {
    if (!widget.isSecret) {
      return;
    }

    // CryptoService has no async init: key pair is generated during registration,
    // and sharedSecret is derived on demand in MessageService.
    _cryptoService ??= CryptoService();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime timestamp) {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');

    return '$hours:$minutes';
  }

  String _shortPublicKey(String publicKey) {
    if (publicKey.length <= 8) {
      return publicKey;
    }

    return '${publicKey.substring(0, 8)}...';
  }

  String _titleText() {
    final nickname = widget.contactNickname.trim();

    if (nickname.isNotEmpty) {
      return nickname;
    }

    return _shortPublicKey(widget.contactPublicKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvixColors.background,
      appBar: AppBar(
        backgroundColor: AvixColors.background,
        foregroundColor: AvixColors.text,
        title: Row(
          children: [
            Expanded(
              child: Text(
                _titleText(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isSecret) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.lock,
                size: 18,
                color: AvixColors.accent,
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildMessagesList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AvixColors.accent,
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Сообщений пока нет',
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _MessageBubble(
          message: _messages[index],
          time: _formatTime(_messages[index].timestamp),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AvixColors.background,
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(color: AvixColors.text),
              cursorColor: AvixColors.accent,
              decoration: InputDecoration(
                hintText: 'Сообщение',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF151515),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AvixColors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: AvixColors.accent,
              foregroundColor: AvixColors.text,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white38,
            ),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isOutgoing
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF2A2A2A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: message.isOutgoing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: AvixColors.text,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isSecret) ...[
                        const Icon(
                          Icons.lock,
                          size: 11,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
