import 'dart:async';

import 'auth_service.dart';
import 'internet_detector.dart';
import 'message_service.dart';
import 'outbox_service.dart';

class SyncService {
  final MessageService _messageService;
  final OutboxService _outboxService;
  final InternetDetector _internetDetector;
  final AuthService _authService;

  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({
    MessageService? messageService,
    OutboxService? outboxService,
    InternetDetector? internetDetector,
    AuthService? authService,
  })  : _messageService = messageService ?? MessageService(),
        _outboxService = outboxService ?? OutboxService(),
        _internetDetector = internetDetector ?? InternetDetector(),
        _authService = authService ?? AuthService();

  Future<void> syncAll() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      await _messageService.syncMessages();
      await _outboxService.processOutbox();
    } finally {
      _isSyncing = false;
    }
  }

  void startPeriodicSync(Duration interval) {
    stopPeriodicSync();

    _syncTimer = Timer.periodic(interval, (_) async {
      final hasInternet = await _internetDetector.hasInternet();
      final token = await _authService.getToken();

      if (!hasInternet || token == null || token.isEmpty) {
        return;
      }

      await syncAll();
    });
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}

extension OutboxServiceSync on OutboxService {
  Future<void> processOutbox() {
    return MessageService().processOutbox();
  }
}
