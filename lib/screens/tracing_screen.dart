import 'package:flutter/material.dart';
import 'package:traceit_app/screens/buildingaccess_screen.dart';

class TracingScreen extends StatelessWidget {
  const TracingScreen({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [Text('data')],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [Text('data')],
            ),
          ],
        ),
      ),
    );
  }
}
