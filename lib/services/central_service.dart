import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:traceit_app/const.dart';

void test_central_service(service) {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Scanning for close contacts',
      content: 'Central mode',
    );
  }

  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();

  flutterReactiveBle
      .scanForDevices(withServices: [Uuid.parse(traceItServiceUuid)]).listen(
    (device) {
      print('Device name: ${device.id}');
      print('Device service UUID: ${device.serviceUuids}');
      print('Device RSSI: ${device.rssi}');
      print('Device RSSI: ${device.manufacturerData}');

      int manufacturerId = device.manufacturerData.buffer
          .asByteData()
          .getUint16(0, Endian.little);

      String manufacturerData = utf8.decode(
          device.manufacturerData.sublist(2, device.manufacturerData.length));
      print('$manufacturerId $manufacturerData');

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Scanning for close contacts',
          content: 'Scanning (Central) ${device.id}',
        );
      }
    },
    onError: (error) {},
  );
}
