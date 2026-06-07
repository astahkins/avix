import 'package:flutter/material.dart';

import '../services/ble_service.dart';

class BleTestScreen extends StatefulWidget {
  const BleTestScreen({super.key});

  @override
  State<BleTestScreen> createState() => _BleTestScreenState();
}

class _BleTestScreenState extends State<BleTestScreen> {
  static const String _testServiceUuid = '12345678-1234-1234-1234-123456789abc';

  final BleService _bleService = BleService();
  String _status = 'Готово';
  bool _isBusy = false;

  @override
  void dispose() {
    _bleService.stop();
    super.dispose();
  }

  Future<void> _startAdvertising() async {
    setState(() {
      _isBusy = true;
      _status = 'Запуск рекламы...';
    });

    try {
      await _bleService.init();
      await _bleService.startAdvertising(
        _testServiceUuid,
        'Hello from Avix',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Рекламирую';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Ошибка рекламы: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isBusy = true;
      _status = 'Запуск сканирования...';
    });

    try {
      await _bleService.init();
      await _bleService.startScanning((data) {
        print('Received: $data');

        if (!mounted) {
          return;
        }

        setState(() {
          _status = 'Получено: $data';
        });

        showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'BLE данные',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                data,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Сканирую';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Ошибка сканирования: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('BLE Test'),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isBusy ? null : _startAdvertising,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Advertising'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isBusy ? null : _startScanning,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
