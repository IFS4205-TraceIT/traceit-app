import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:traceit_app/screens/buildingaccess_screen.dart';
import 'package:traceit_app/services/bluetooth_service.dart';

class TracingScreen extends StatefulWidget {
  const TracingScreen({super.key});

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends State<TracingScreen> {
  bool bluetoothServiceIsRunning = false;
  late FlutterBackgroundService bluetoothService;

  void startBluetoothService() async {
    // Initialise Bluetooth service if not running
    if (!bluetoothServiceIsRunning) {
      await initialiseBluetoothService().then((service) {
        bluetoothService = service;

        setState(() {
          bluetoothServiceIsRunning = true;
        });
      });
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
            Text('Service running: $bluetoothServiceIsRunning'),
            ElevatedButton(
              onPressed: () => startBluetoothService(),
              child: const Text('Start Service'),
            ),
            ElevatedButton(
              onPressed: () {
                if (bluetoothServiceIsRunning) {
                  bluetoothService.invoke('stopService');
                  setState(() {
                    bluetoothServiceIsRunning = false;
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
