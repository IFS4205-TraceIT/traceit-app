import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:traceit_app/const.dart';

class BleAdvertiser {
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  Future<bool> isPeripheralSupported() async {
    return await blePeripheral.isSupported;
  }

  Future<bool> isAdvertising() async {
    return await blePeripheral.isAdvertising;
  }

  void startAdvertising() async {
    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: traceItServiceUuid,
      manufacturerId: 4205,
      manufacturerData: Uint8List.fromList(utf8.encode('TraceIT')),
    );

    final AdvertiseSettings advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowPower,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeout: 60 * 1000,
    );

    // final AdvertiseSetParameters advertiseSetParameters =
    //     AdvertiseSetParameters(
    //   txPowerLevel: txPowerHigh,
    //   duration: 60 * 1000,
    //   connectable: true,
    // );

    if (!(await isPeripheralSupported())) {
      return;
    }

    await blePeripheral.start(
      advertiseData: advertiseData,
      // advertiseSetParameters: advertiseSetParameters,
      advertiseSettings: advertiseSettings,
    );
  }

  void stopAdvertising() async {
    await blePeripheral.stop();
  }
}
