import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:traceit_app/const.dart';

void test_peripheral_service(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Scanning for close contacts',
      content: 'Peripheral mode',
    );
  }

  final AdvertiseData advertiseData = AdvertiseData(
    serviceUuid: traceItServiceUuid,
    manufacturerId: 4205,
    manufacturerData: Uint8List.fromList(utf8.encode('TraceIT')),
  );

  final AdvertiseSettings advertiseSettings = AdvertiseSettings(
    advertiseMode: AdvertiseMode.advertiseModeBalanced,
    txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
    timeout: 60 * 1000,
  );

  final AdvertiseSetParameters advertiseSetParameters = AdvertiseSetParameters(
    txPowerLevel: txPowerHigh,
    duration: 60 * 1000,
    connectable: true,
  );

  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  bool isPeripheralSupported = await blePeripheral.isSupported;

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Scanning for close contacts',
      content: 'Peripheral supported: $isPeripheralSupported',
    );
  }

  if (!isPeripheralSupported) {
    return;
  }

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Scanning for close contacts (Peripheral)',
      content: 'Advertising: ${await blePeripheral.isAdvertising}',
    );
  }

  await blePeripheral.start(
    advertiseData: advertiseData,
    advertiseSetParameters: advertiseSetParameters,
  );

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Scanning for close contacts (Peripheral)',
      content: 'Advertising: ${await blePeripheral.isAdvertising}',
    );
  }
}
