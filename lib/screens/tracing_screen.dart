import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:traceit_app/screens/buildingaccess_screen.dart';
import 'package:traceit_app/services/bluetooth_service.dart';
import 'package:traceit_app/services/gatt_server.dart';

class TracingScreen extends StatefulWidget {
  const TracingScreen({super.key});

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends State<TracingScreen> {
  bool _bluetoothServiceIsRunning = false;
  late FlutterBackgroundService _bluetoothService;

  final GattServer _gattServer = GattServer();

  void startBluetoothService() async {
    // Initialise Bluetooth service if not running
    if (!_bluetoothServiceIsRunning) {
      await initialiseBluetoothService().then((service) {
        _bluetoothService = service;

        setState(() {
          _bluetoothServiceIsRunning = true;
        });
      });

      // Start GATT server
      _gattServer.startGattServer();
    }
  }

  @override
  void initState() {
    super.initState();
    startBluetoothService();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Service running: $_bluetoothServiceIsRunning'),
            ElevatedButton(
              onPressed: () => startBluetoothService(),
              child: const Text('Start Service'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_bluetoothServiceIsRunning) {
                  _bluetoothService.invoke('stopService');
                  setState(() {
                    _bluetoothServiceIsRunning = false;
                  });
                }
              },
              child: const Text('Stop Service'),
            ),
          ],
        ),
      ),
    );
  }
}
