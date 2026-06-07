import 'dart:async';

import 'package:flutter/material.dart';

import '../services/p2p_service.dart';

class P2PTestScreen extends StatefulWidget {
  const P2PTestScreen({super.key});

  @override
  State<P2PTestScreen> createState() => _P2PTestScreenState();
}

class _P2PTestScreenState extends State<P2PTestScreen> {
  final P2PService _p2pService = P2PService();
  final TextEditingController _deviceNameController =
      TextEditingController(text: 'Avix Device');
  final TextEditingController _messageController = TextEditingController();

  StreamSubscription<List<Device>>? _devicesSubscription;
  StreamSubscription<String>? _messagesSubscription;

  List<Device> _devices = [];
  final List<String> _logs = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initP2P();
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _messagesSubscription?.cancel();
    _deviceNameController.dispose();
    _messageController.dispose();
    _p2pService.dispose();
    super.dispose();
  }

  Future<void> _initP2P() async {
    try {
      await _p2pService.init();

      _devicesSubscription = _p2pService.devicesStream.listen((devices) {
        if (!mounted) {
          return;
        }

        setState(() {
          _devices = devices;
        });
      });

      _messagesSubscription = _p2pService.messagesStream.listen((message) {
        _addLog('Received: $message');
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitialized = true;
      });

      _addLog('P2P initialized');
    } catch (error) {
      _addLog('Init error: $error');
    }
  }

  void _startAdvertising() {
    final displayName = _deviceNameController.text.trim();
    if (displayName.isEmpty) {
      _addLog('Введите имя устройства');
      return;
    }

    _p2pService.startAdvertising(displayName);
    _addLog('Advertising: $displayName');
  }

  void _startDiscovery() {
    _p2pService.startDiscovery();
    _addLog('Discovery started');
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _addLog('Введите сообщение');
      return;
    }

    _p2pService.sendMessage(message);
    _messageController.clear();
    _addLog('Sent: $message');
  }

  void _sendHelloToDevice(Device device) {
    final displayName = _deviceNameController.text.trim().isEmpty
        ? 'Avix'
        : _deviceNameController.text.trim();
    final message = 'Hello from $displayName';

    _p2pService.sendMessage(message);
    _addLog('Sent to ${device.deviceName}: $message');
  }

  void _addLog(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _logs.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('P2P Test'),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _deviceNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Device name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _startAdvertising : null,
                      style: _buttonStyle(),
                      child: const Text('Start Advertising'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _startDiscovery : null,
                      style: _buttonStyle(),
                      child: const Text('Start Discovery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Devices',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: _panelDecoration(),
                  child: _devices.isEmpty
                      ? const Center(
                          child: Text(
                            'No devices found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];

                            return ListTile(
                              title: Text(
                                device.deviceName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                device.deviceAddress,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () => _sendHelloToDevice(device),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: _panelDecoration(),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Message'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isInitialized ? _sendMessage : null,
                    style: _buttonStyle(),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E88E5)),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E88E5),
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFF2A2A2A),
      disabledForegroundColor: Colors.white38,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF2A2A2A)),
    );
  }
}
