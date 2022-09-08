import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:traceit_app/const.dart';

class BLEAdvertiser {
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  final AdvertiseData advertiseData = AdvertiseData(
    serviceUuid: serviceUuid,
    // manufacturerId: 4205,
    // manufacturerData: Uint8List.fromList(utf8.encode('TraceIT')),
  );

  // final AdvertiseSettings advertiseSettings = AdvertiseSettings(
  //   advertiseMode: AdvertiseMode.advertiseModeBalanced,
  //   txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
  //   timeout: 60 * 1000,
  // );

  final AdvertiseSetParameters advertiseSetParameters = AdvertiseSetParameters(
    txPowerLevel: txPowerHigh,
    duration: 60 * 1000,
    connectable: true,
  );

  Future<bool> isSupported() async {
    return await blePeripheral.isSupported;
  }

  Future<bool> isConnected() async {
    return await blePeripheral.isConnected;
  }

  Future<bool> isAdvertising() async {
    return await blePeripheral.isAdvertising;
  }

  Future<void> startAdvertising() async {
    bool isSupported = await blePeripheral.isSupported;

    if (!isSupported) {
      return;
    }

    await blePeripheral.start(
      advertiseData: advertiseData,
      advertiseSetParameters: advertiseSetParameters,
    );
  }

  Future<void> stopAdvertising() async {
    blePeripheral.stop();
  }
}
