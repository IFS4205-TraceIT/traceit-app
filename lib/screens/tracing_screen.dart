import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:traceit_app/const.dart';
import 'package:traceit_app/screens/buildingaccess_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:traceit_app/screens/login_screen.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage/storage.dart';
import 'package:traceit_app/tracing/central/ble_client.dart';
import 'package:traceit_app/tracing/peripheral/gatt_server.dart';
import 'package:traceit_app/tracing/peripheral/ble_advertiser.dart';

class TracingScreen extends StatefulWidget {
  const TracingScreen({super.key});

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends State<TracingScreen> {
  final Storage _storage = Storage();

  late String _deviceModel;

  bool _peripheralServiceRunning = false;
  bool _centralServiceRunning = false;

  // Peripheral BLE advertiser
  final BLEAdvertiser _bleAdvertiser = BLEAdvertiser();
  bool _bleAdvertisementSupported = false;
  bool _bleAdvertising = false;

  // Peripheral GATT server
  final GattServer _gattServer = GattServer();
  bool _gattServerRunning = false;

  // Central BLE scanner
  final BLEClient _bleClient = BLEClient();
  bool _bleScanning = false;

  late FBroadcast _closeContactReceiver;
  int _closeContactCount = 0;

  void showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  Future<void> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _deviceModel = androidInfo.model!;
    });
    debugPrint('Running on ${androidInfo.model}');
  }

  Future<void> checkAdvertisingSupport() async {
    bool isSupported = await _bleAdvertiser.isSupported();
    setState(() {
      _bleAdvertisementSupported = isSupported;
    });
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
    await _bleAdvertiser.startAdvertising();

    setState(() {
      _bleAdvertising = true;
    });
  }

  Future<void> stopAdvertising() async {
    await _bleAdvertiser.stopAdvertising();

    setState(() {
      _bleAdvertising = false;
    });
  }

  Future<void> startGattServer() async {
    await _gattServer.start();

    bool gattServerRunning = await _gattServer.isRunning();

    setState(() {
      _gattServerRunning = gattServerRunning;
    });
  }

  Future<void> stopGattServer() async {
    await _gattServer.stop();

    bool gattServerRunning = await _gattServer.isRunning();

    setState(() {
      _gattServerRunning = gattServerRunning;
    });
  }

  void startCentralService() {
    if (_centralServiceRunning) {
      return;
    }

    setState(() {
      _centralServiceRunning = true;
    });

    startScanning();
  }

  void startScanning() {
    _bleClient.initScan();

    setState(() {
      _bleScanning = true;
    });
  }

  void stopScanning() {
    _bleClient.stopScan();

    setState(() {
      _bleScanning = false;
    });
  }

  Future<void> logout() async {
    // Check if tokens need to be refreshed
    Map<String, String?> tokens = await _storage.getTokens();
    Map<String, String>? refreshedTokens = await ServerAuth.checkRefreshToken(
      tokens['accessToken']!,
      tokens['refreshToken']!,
    );

    if (refreshedTokens != null) {
      // Tokens not changed or refreshed
      // Save tokens
      await _storage.saveTokens(
        refreshedTokens['accessToken']!,
        refreshedTokens['refreshToken']!,
      );
    } else {
      // Tokens invalid
      debugPrint('Tokens invalid. Not refreshed.');
      showSnackbar('Session expired');

      // Delete tokens
      await _storage.deleteTokens();

      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    // Send logout request to server
    Response response = await ServerAuth.logout();

    if (response.statusCode == 204) {
      // Stop tracing services
      if (_peripheralServiceRunning) {
        debugPrint('Stopping peripheral service');
        await stopAdvertising();
        await stopGattServer();
      } else if (_centralServiceRunning) {
        debugPrint('Stopping central service');
        stopScanning();
      }

      // Delete tokens from storage
      await _storage.deleteTokens();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      debugPrint(response.body);
      showSnackbar('Logout failed');
    }
  }

  @override
  void initState() {
    super.initState();

    getDeviceInfo().then((value) {
      checkAdvertisingSupport();

      // TODO: remove at a later point
      if (_deviceModel == 'SM-N920I') {
        // Peripheral
        startPeripheralService();
      } else {
        // Central
        startCentralService();
      }
    });

    // Register broadcast receiver for close contact count
    _closeContactReceiver = FBroadcast.instance().register(
      closeContactBroadcastKey,
      ((value, callback) {
        setState(() {
          _closeContactCount = value;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TraceIT'),
        automaticallyImplyLeading: false,
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
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 1,
                  child: Text('Logout'),
                )
              ];
            },
            onSelected: (value) {
              switch (value) {
                case 1:
                  logout();
                  break;
                default:
                  break;
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          children: [
            Text(
              'Close Contacts',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(
              _closeContactCount.toString(),
              style: Theme.of(context).textTheme.headline1,
            ),
            Text(
                'Mode: ${_peripheralServiceRunning ? 'Peripheral' : 'Central'}'),
            Text('Advertisement Support: $_bleAdvertisementSupported'),
            // Peripheral (Advertiser/Server) controls
            Visibility(
              visible: _peripheralServiceRunning,
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Text('BLE Advertising: $_bleAdvertising'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: (() => _bleAdvertisementSupported
                            ? startAdvertising()
                            : null),
                        child: const Text('Start Advertiser'),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: (() => _bleAdvertisementSupported
                            ? stopAdvertising()
                            : null),
                        child: const Text('Stop Advertiser'),
                      ),
                    ],
                  ),
                  Text('GATT Server Running: $_gattServerRunning'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: startGattServer,
                        child: const Text('Start GATT Server'),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: stopGattServer,
                        child: const Text('Stop GATT Server'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Central (Scanner/Client) controls
            Visibility(
              visible: _centralServiceRunning,
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Text('Client scanning: $_bleScanning'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: startScanning,
                        child: const Text('Start scanning'),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: stopScanning,
                        child: const Text('Stop scanning'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
