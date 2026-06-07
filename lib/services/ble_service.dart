import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static const String defaultServiceUuid = '8f3d4f3d-4d8b-4a6e-9f3d-7e9b2f0a7a11';

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  String _serviceUuid = defaultServiceUuid;

  Future<void> init() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      print('Bluetooth не поддерживается на этом устройстве');
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      print('Bluetooth выключен');
    }
  }

  Future<void> startAdvertising(String serviceUuid, String data) async {
    try {
      _serviceUuid = serviceUuid;

      final permissions = await [
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();

      final hasPermissions = permissions.values.every((status) {
        return status.isGranted || status.isLimited;
      });

      if (!hasPermissions) {
        throw Exception('Нет разрешений для BLE advertising');
      }

      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        throw Exception('Bluetooth не поддерживается на этом устройстве');
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth выключен');
      }

      final advertisementPayload = {
        'includeTxPower': true,
        'serviceUuids': [serviceUuid],
        'serviceData': {
          serviceUuid: utf8.encode(data),
        },
      };

      // flutter_blue_plus поддерживает Central role и не имеет startAdvertising.
      // Реальный Peripheral/Advertising позже нужно подключить через отдельный BLE advertising plugin.
      print('BLE advertising payload: $advertisementPayload');
    } catch (error) {
      print('Ошибка запуска BLE advertising: $error');
      rethrow;
    }
  }

  Future<void> startScanning(Function(String data) onDataReceived) async {
    try {
      final permissions = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final hasPermissions = permissions.values.every((status) {
        return status.isGranted || status.isLimited;
      });

      if (!hasPermissions) {
        throw Exception('Нет разрешений для BLE scanning');
      }

      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        throw Exception('Bluetooth не поддерживается на этом устройстве');
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth выключен');
      }

      final serviceGuid = Guid(_serviceUuid);

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final result in results) {
            final serviceData = result.advertisementData.serviceData;
            final bytes = serviceData[serviceGuid];

            if (bytes == null || bytes.isEmpty) {
              continue;
            }

            try {
              onDataReceived(utf8.decode(bytes));
            } catch (error) {
              print('Ошибка декодирования BLE serviceData: $error');
            }
          }
        },
        onError: (error) {
          print('Ошибка BLE scanResults: $error');
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        withServices: [serviceGuid],
        androidUsesFineLocation: true,
      );
    } catch (error) {
      print('Ошибка запуска BLE scanning: $error');
      await stop();
      rethrow;
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    print('Подключение к $deviceId');
  }

  Future<void> sendMessageViaBle(String deviceId, String message) async {
    print('Отправка BLE: $message устройству $deviceId');
  }

  Future<void> stop() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
  }
}
