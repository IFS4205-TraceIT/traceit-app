import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:traceit_app/const.dart';

void test_peripheral_service() async {
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

  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  bool isPeripheralSupported = await blePeripheral.isSupported;

  if (!isPeripheralSupported) {
    return;
  }

  await blePeripheral.start(
    advertiseData: advertiseData,
    advertiseSetParameters: advertiseSetParameters,
  );
}
