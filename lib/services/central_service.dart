import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:traceit_app/const.dart';

void test_central_service() {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();

  flutterReactiveBle
      .scanForDevices(withServices: [Uuid.parse(serviceUuid)]).listen(
    (device) {
      print(device);
      // print('Device name: ${device.id}');
      // print('Device service UUID: ${device.serviceUuids}');
      // print('Device RSSI: ${device.rssi}');
      // print('Device RSSI: ${device.manufacturerData}');

      int manufacturerId = device.manufacturerData.buffer
          .asByteData()
          .getUint16(0, Endian.little);

      String manufacturerData = utf8.decode(
          device.manufacturerData.sublist(2, device.manufacturerData.length));
      print('$manufacturerId $manufacturerData');
    },
    onError: (error) {},
  );
}
