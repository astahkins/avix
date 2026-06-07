import 'package:connectivity_plus/connectivity_plus.dart';

import 'ble_service.dart';
import 'internet_detector.dart';
import 'message_service.dart';

enum TransportType {
  internet,
  ble,
  wifiDirect,
  offline,
}

class ConnectionManager {
  final InternetDetector _internetDetector;
  final Connectivity _connectivity;
  final BleService bleService;

  ConnectionManager({
    InternetDetector? internetDetector,
    Connectivity? connectivity,
    BleService? bleService,
  })  : _internetDetector = internetDetector ?? InternetDetector(),
        _connectivity = connectivity ?? Connectivity(),
        bleService = bleService ?? BleService();

  Future<TransportType> getCurrentTransport() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final hasNetworkInterface = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasNetworkInterface) {
      final hasInternet = await _internetDetector.hasInternet();

      if (hasInternet) {
        return TransportType.internet;
      }
    }

    final hasBleDevices = await _tryDetectBleDevices();
    if (hasBleDevices) {
      return TransportType.ble;
    }

    return TransportType.offline;
  }

  Future<void> onInternetLost() async {
    print('Переход на офлайн-режим');
    await bleService.stop();

    await bleService.startScanning((data) {
      print('Получены BLE данные: $data');
    });

    // Реальная BLE-реклама будет добавлена после подключения Peripheral-role плагина.
    await bleService.startAdvertising(
      BleService.defaultServiceUuid,
      'avix-offline-ready',
    );
  }

  Future<void> onInternetRestored() async {
    print('Возврат на интернет-канал');
    await bleService.stop();
    // Later this will be called from a real connectivity listener.
    await MessageService().processOutbox();
  }

  Future<void> sendViaBle(String message, String targetPublicKey) async {
    await bleService.sendMessageViaBle(targetPublicKey, message);
  }

  Future<bool> _tryDetectBleDevices() async {
    var hasBleDevices = false;

    await bleService.startScanning((data) {
      hasBleDevices = true;
      print('Найден BLE-пакет Avix: $data');
    });

    await Future.delayed(const Duration(seconds: 3));

    if (!hasBleDevices) {
      await bleService.stop();
    }

    return hasBleDevices;
  }
}
