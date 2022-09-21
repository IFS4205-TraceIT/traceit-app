import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:traceit_app/const.dart';
import 'package:traceit_app/storage/storage.dart';

class BLEClient {
  final Storage storage = Storage();

  final FlutterReactiveBle _bleClient = FlutterReactiveBle();
  late StreamSubscription? _scanStream;
  bool _isScanning = false;

  final List _discoveredDevices = <String>[];

  StreamSubscription<ConnectionStateUpdate>? _currentConnection;

  void _onScanResult(DiscoveredDevice device) async {
    debugPrint(device.toString());
    // print('Device name: ${device.id}');
    // print('Device service UUID: ${device.serviceUuids}');
    // print('Device RSSI: ${device.rssi}');
    // print('Device RSSI: ${device.manufacturerData}');

    // int manufacturerId =
    //     device.manufacturerData.buffer.asByteData().getUint16(0, Endian.little);
    // String manufacturerData = utf8.decode(
    //     device.manufacturerData.sublist(2, device.manufacturerData.length));
    // debugPrint('$manufacturerId $manufacturerData');

    // TODO: Check if device is already in discovered list
    // if (!_discoveredDevices.contains(device.id)) {
    // _discoveredDevices.add(device.id);
    _connectToDevice(device);
    // }
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
        // Request larger MTU
        int mtu = await _bleClient.requestMtu(
            deviceId: connectionState.deviceId, mtu: 247);
        debugPrint('Negotiated MTU: $mtu');

        // Read characteristic data
        List<int> readData = await _bleClient.readCharacteristic(
          QualifiedCharacteristic(
            serviceId: Uuid.parse(serviceUuid),
            characteristicId: Uuid.parse(characteristicUuid),
            deviceId: connectionState.deviceId,
          ),
        );

        // TODO: save data to device
        Map receivedData = jsonDecode(utf8.decode(readData));
        await storage.writeCloseContact(receivedData['id'], rssi);
        debugPrint('Received characteristic data : ${receivedData.toString()}');

        // TODO: check if current temp ID is valid

        // Prepare write characteristic data
        Map<String, dynamic> writeData = {
          'id':
              '4qS6+bFwTVtDZOuhI6dxDJwBZmt6Nl1UVULmOraUtxu20qn1T5BcmXF9GycVjEZxWxtjFofUUNZCkUJrbEYAqyA1t7zCQGmfHQPEO5+M2VBeJIs4BabrCfAi6x8evBSpKQ==',
          'rssi': rssi,
        };

        debugPrint('Characteristic write data: ${jsonEncode(writeData)}');

        // Write characteristic data
        await _bleClient.writeCharacteristicWithResponse(
          QualifiedCharacteristic(
            serviceId: Uuid.parse(serviceUuid),
            characteristicId: Uuid.parse(characteristicUuid),
            deviceId: connectionState.deviceId,
          ),
          value: jsonEncode(writeData).codeUnits,
        );

        // Disconnect from GATT server
        _currentConnection!.cancel();
        _currentConnection = null;

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
    // Clear discovered devices
    _discoveredDevices.clear();

    startScan();
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
