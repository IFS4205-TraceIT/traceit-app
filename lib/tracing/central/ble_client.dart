import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:traceit_app/const.dart';
import 'package:traceit_app/storage/storage.dart';
import 'package:traceit_app/tempid/tempid_manager.dart';

class BLEClient {
  final Storage _storage = Storage();
  final TempIdManager _tempIdManager = TempIdManager();

  final FlutterReactiveBle _bleClient = FlutterReactiveBle();
  late StreamSubscription? _scanStream;
  bool _isScanning = false;

  final List _recentDevices = <String>[];

  StreamSubscription<ConnectionStateUpdate>? _currentConnection;

  void _onScanResult(DiscoveredDevice device) async {
    debugPrint(device.toString());

    if (!_recentDevices.contains(device.id)) {
      _connectToDevice(device);
    } else {
      debugPrint('Device ${device.id} already in discovered list');
    }
  }

  void _connectToDevice(DiscoveredDevice device) {
    // Stop scanning for advertisements
    stopScan();

    // Connect to GATT server
    _currentConnection = _bleClient
        .connectToAdvertisingDevice(
      id: device.id,
      withServices: [Uuid.parse(serviceUuid)],
      prescanDuration: const Duration(seconds: 5),
      servicesWithCharacteristicsToDiscover: {
        Uuid.parse(serviceUuid): [Uuid.parse(characteristicUuid)]
      },
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((connectionState) {
      _onConnectionStateChange(connectionState, device.rssi);
    }, onError: (error) {
      debugPrint('error : ${error.toString()}');
    });
  }

  void _onConnectionStateChange(
      ConnectionStateUpdate connectionState, int rssi) async {
    debugPrint('connectionState : ${connectionState.toString()}');

    switch (connectionState.connectionState) {
      case DeviceConnectionState.connecting:
        break;
      case DeviceConnectionState.connected:
        bool readSuccess = false;
        bool writeSuccess = false;

        // Request larger MTU
        int mtu = await _bleClient.requestMtu(
            deviceId: connectionState.deviceId, mtu: 247);
        debugPrint('Negotiated MTU: $mtu');

        // Read characteristic data
        late List<int> readData;
        try {
          readData = await _bleClient.readCharacteristic(
            QualifiedCharacteristic(
              serviceId: Uuid.parse(serviceUuid),
              characteristicId: Uuid.parse(characteristicUuid),
              deviceId: connectionState.deviceId,
            ),
          );

          readSuccess = true;
        } catch (e) {
          debugPrint('Error reading characteristic: $e');
          // Disconnect from GATT server
          _currentConnection!.cancel();
          _currentConnection = null;
          return;
        }

        // Save data to device
        Map receivedData = jsonDecode(utf8.decode(readData));
        await _storage.writeCloseContact(receivedData['id'], rssi);
        debugPrint('Received characteristic data : ${receivedData.toString()}');

        // Prepare write characteristic data
        String tempId = await _tempIdManager.getTempId();
        Map<String, dynamic> writeData = {
          'id': tempId,
          'rssi': rssi,
        };

        debugPrint('Characteristic write data: ${jsonEncode(writeData)}');

        // Write characteristic data
        try {
          await _bleClient.writeCharacteristicWithResponse(
            QualifiedCharacteristic(
              serviceId: Uuid.parse(serviceUuid),
              characteristicId: Uuid.parse(characteristicUuid),
              deviceId: connectionState.deviceId,
            ),
            value: jsonEncode(writeData).codeUnits,
          );

          writeSuccess = true;
        } catch (e) {
          debugPrint('Error writing characteristic: $e');
        }

        // Disconnect from GATT server
        _currentConnection!.cancel();
        _currentConnection = null;

        // Add device to discovered list
        if (readSuccess && writeSuccess) {
          _recentDevices.add(connectionState.deviceId);
        }

        // Starting from Android 7 you could not start the BLE scan more than
        // 5 times per 30 seconds
        // Delay before restarting scan
        await Future.delayed(const Duration(seconds: 10), () => startScan());
        break;
      case DeviceConnectionState.disconnecting:
        break;
      case DeviceConnectionState.disconnected:
        break;
    }
  }

  bool get isScanning {
    return _isScanning;
  }

  void initScan() {
    startScan();
  }

  void clearRecentDevices() {
    _recentDevices.clear();
  }

  void startScan() {
    debugPrint('Scan started for service UUID $serviceUuid');

    _scanStream = _bleClient.scanForDevices(
        withServices: [Uuid.parse(serviceUuid)],
        scanMode: ScanMode.balanced).listen(
      ((device) => _onScanResult(device)),
      onDone: () => debugPrint('Scan done'),
      onError: (error) {
        debugPrint(error.toString());
      },
    );

    _isScanning = true;
  }

  void stopScan() {
    if (_scanStream == null) {
      debugPrint('Scan not stopped. Not currently running');
      return;
    }

    debugPrint('Scan stopped');
    _scanStream!.cancel();
    _scanStream = null;

    _isScanning = false;
  }
}
