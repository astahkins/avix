import 'dart:async';

import 'package:wifi_direct_plugin/wifi_direct_plugin.dart';

typedef Device = WifiDirectDevice;

class P2PService {
  final StreamController<String> _messagesController =
      StreamController<String>.broadcast();

  Future<void> init() async {
    await WifiDirectPlugin.initialize();

    WifiDirectPlugin.onTextReceived = (message) {
      _messagesController.add(message);
    };
  }

  void startAdvertising(String displayName) {
    _runSafely(() async {
      await WifiDirectPlugin.startAsServer(displayName);
    });
  }

  void startDiscovery() {
    _runSafely(() async {
      await WifiDirectPlugin.startDiscovery();
    });
  }

  void sendMessage(String message) {
    _runSafely(() async {
      await WifiDirectPlugin.sendText(message);
    });
  }

  void stopAll() {
    _runSafely(() async {
      await WifiDirectPlugin.stopDiscovery();
      await WifiDirectPlugin.disconnect();
      await WifiDirectPlugin.cleanup();
    });
  }

  Stream<List<Device>> get devicesStream => WifiDirectPlugin.peersStream;

  Stream<String> get messagesStream => _messagesController.stream;

  void dispose() {
    stopAll();
    _messagesController.close();
  }

  void _runSafely(Future<void> Function() action) {
    Future<void>(() async {
      try {
        await action();
      } catch (error) {
        print('P2PService error: $error');
      }
    });
  }
}
