import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:traceit_app/const.dart';

class BLEClient {
  final FlutterReactiveBle _ble_client = FlutterReactiveBle();
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

    // if (!_discoveredDevices.contains(device.id)) {
    // _discoveredDevices.add(device.id);
    _connectToDevice(device);
    // }
  }

  void _connectToDevice(DiscoveredDevice device) {
    // Stop scanning for advertisements
    stopScan();

    // Connect to GATT server
    _currentConnection = _ble_client
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
      _onConnectionStateChange(connectionState);
    }, onError: (error) {
      debugPrint('error : ${error.toString()}');
    });
  }

  void _onConnectionStateChange(ConnectionStateUpdate connectionState) async {
    debugPrint('connectionState : ${connectionState.toString()}');

    switch (connectionState.connectionState) {
      case DeviceConnectionState.connecting:
        break;
      case DeviceConnectionState.connected:
        List<int> readData =
            await _ble_client.readCharacteristic(QualifiedCharacteristic(
          serviceId: Uuid.parse(serviceUuid),
          characteristicId: Uuid.parse(characteristicUuid),
          deviceId: connectionState.deviceId,
        ));

        debugPrint('Received characteristic data : ${utf8.decode(readData)}');

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

    _scanStream = _ble_client.scanForDevices(
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
