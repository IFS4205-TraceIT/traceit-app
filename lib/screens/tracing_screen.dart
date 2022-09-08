import 'package:flutter/material.dart';
import 'package:traceit_app/screens/buildingaccess_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:traceit_app/tracing/peripheral/gatt_server.dart';
import 'package:traceit_app/tracing/peripheral/ble_advertiser.dart';
import 'package:traceit_app/services/central_service.dart';

class TracingScreen extends StatefulWidget {
  const TracingScreen({super.key});

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends State<TracingScreen> {
  late String deviceModel;

  bool _peripheralServiceRunning = false;
  bool _centralServiceRunning = false;

  late BLEAdvertiser _bleAdvertiser = BLEAdvertiser();
  late bool _bleAdvertisementSupported = false;
  bool _bleAdvertising = false;

  late GattServer _gattServer = GattServer();
  bool _gattServerRunning = false;

  Future<void> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      deviceModel = androidInfo.model!;
    });
    debugPrint('Running on ${androidInfo.model}');
  }

  Future<void> startPeripheralService() async {
    if (_peripheralServiceRunning) {
      return;
    }

    bool advertisementSupported = await _bleAdvertiser.isSupported();

    setState(() {
      _peripheralServiceRunning = true;
      _bleAdvertisementSupported = advertisementSupported;
    });

    await startAdvertising();
    await startGattServer();
  }

  Future<void> startAdvertising() async {
    if (!_bleAdvertisementSupported || _bleAdvertising) {
      return;
    }

    await _bleAdvertiser.startAdvertising();

    setState(() {
      _bleAdvertising = true;
    });
  }

  Future<void> stopAdvertising() async {
    if (!_bleAdvertisementSupported || !_bleAdvertising) {
      return;
    }

    await _bleAdvertiser.stopAdvertising();

    setState(() {
      _bleAdvertising = false;
    });
  }

  Future<void> startGattServer() async {
    await _gattServer.start();
    setState(() {
      _gattServerRunning = true;
    });
  }

  Future<void> stopGattServer() async {
    await _gattServer.stop();
    setState(() {
      _gattServerRunning = false;
    });
  }

  @override
  void initState() {
    super.initState();

    getDeviceInfo().then((value) {
      if (deviceModel == 'SM-N920I') {
        // Peripheral
        startPeripheralService();
      } else {
        // Central
        test_central_service();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('TraceIT'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: ((context) => const QRCodeScannerScreen()),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Building QR Code',
          ),
        ],
      ),
      body: Center(
        child: Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          children: [
            Text('Advertisement Support: $_bleAdvertisementSupported'),
            Text('BLE Advertising: $_bleAdvertising'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (() =>
                      _bleAdvertisementSupported ? startAdvertising() : null),
                  child: const Text('Start Advertiser'),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: (() =>
                      _bleAdvertisementSupported ? stopAdvertising() : null),
                  child: const Text('Stop Advertiser'),
                ),
              ],
            ),
            Text('GATT Sever Running: $_gattServerRunning'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (() => startGattServer()),
                  child: const Text('Start GATT Server'),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: (() => stopGattServer()),
                  child: const Text('Stop GATT Server'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
