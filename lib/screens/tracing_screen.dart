import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/material.dart';
import 'package:traceit_app/const.dart';
import 'package:traceit_app/contact_upload_manager.dart';
import 'package:traceit_app/screens/building_access_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:traceit_app/screens/contact_upload_screen.dart';
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

  ContactUploadManager _contactUploadManager = ContactUploadManager();
  String _contactStatus = '';

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

    if (await _bleAdvertiser.isAdvertising()) {
      await _bleAdvertiser.stopAdvertising();
    }

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
    Map<String, String>? tokens = await ServerAuth.getTokens();
    if (tokens == null) {
      // Tokens invalid
      debugPrint('Tokens invalid. Not refreshed.');
      showSnackbar('Session expired');

      // Delete temp IDs
      _storage.deleteAllTempIds();

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

    // Tokens not changed or refreshed
    // Save tokens
    await _storage.saveTokens(
      tokens['accessToken']!,
      tokens['refreshToken']!,
    );

    // Send logout request to server
    bool logoutSuccessful = await ServerAuth.logout();

    if (logoutSuccessful) {
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
      showSnackbar('Logout failed');
    }
  }

  Future<void> _getContactStatus() async {
    String? contactStatus = await _contactUploadManager.getContactStatus();
    if (contactStatus == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    late String displayStatus;

    switch (contactStatus) {
      case 'positive':
        displayStatus = 'Positive';
        break;
      case 'negative':
        displayStatus = 'Negative';
        break;
      case 'close':
        displayStatus = 'Close Contact';
        break;
      default:
        displayStatus = 'Failed to retrieve status';
        break;
    }

    setState(() {
      _contactStatus = displayStatus;
    });
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

    // Get contact status
    _getContactStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TraceIT'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => {
              // Navigate to contact upload screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactUploadScreen(),
                ),
              ),
            },
            icon: const Icon(Icons.upload),
            tooltip: 'Upload close contact data',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to scanner screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: ((context) => const BuildingAccessScreen()),
            ),
          );
        },
        tooltip: 'Scan Building QR Code',
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _getContactStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 150,
            child: Center(
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                children: [
                  const Text(
                    'Your Contact Status',
                  ),
                  Text(
                    _contactStatus,
                    style: Theme.of(context).textTheme.headline6,
                  ),
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
          ),
        ),
      ),
    );
  }
}
