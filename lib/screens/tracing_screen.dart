import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:traceit_app/const.dart';
import 'package:traceit_app/contact_upload_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage/storage.dart';
import 'package:traceit_app/tracing/central/ble_client.dart';
import 'package:traceit_app/tracing/peripheral/gatt_server.dart';
import 'package:traceit_app/tracing/peripheral/ble_advertiser.dart';
import 'package:traceit_app/tracing/tracing_scheduler.dart';
import 'package:traceit_app/utils.dart';

class TracingScreen extends StatefulWidget {
  const TracingScreen({super.key});

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends State<TracingScreen> {
  final Storage _storage = Storage();

  // Tracing scheduler
  final TracingScheduler _tracingScheduler = TracingScheduler();
  late TracingMode _currentTracingMode;

  late String _deviceModel;

  // Tracing service running state
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

  int _closeContactCount = 0;

  final ContactUploadManager _contactUploadManager = ContactUploadManager();
  String _contactStatus = '';

  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _deviceModel = androidInfo.model!;
    });
    debugPrint('Running on ${androidInfo.model}');
  }

  Future<void> _checkAdvertisingSupport() async {
    bool isSupported = await _bleAdvertiser.isSupported();
    setState(() {
      _bleAdvertisementSupported = isSupported;
    });
  }

  Future<void> _startAdvertising() async {
    await _bleAdvertiser.startAdvertising();

    setState(() {
      _bleAdvertising = true;
    });
  }

  Future<void> _stopAdvertising() async {
    await _bleAdvertiser.stopAdvertising();

    setState(() {
      _bleAdvertising = false;
    });
  }

  Future<void> _startGattServer() async {
    await _gattServer.start();

    bool gattServerRunning = await _gattServer.isRunning();

    setState(() {
      _gattServerRunning = gattServerRunning;
    });
  }

  Future<void> _stopGattServer() async {
    await _gattServer.stop();

    bool gattServerRunning = await _gattServer.isRunning();

    setState(() {
      _gattServerRunning = gattServerRunning;
    });
  }

  Future<void> _startPeripheralService() async {
    debugPrint('Starting peripheral service');

    if (_peripheralServiceRunning) {
      debugPrint('Peripheral service already running');
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

    await _startGattServer();
    await _startAdvertising();
  }

  Future<void> _stopPeripheralService() async {
    debugPrint('Stopping peripheral service');
    if (!_peripheralServiceRunning) {
      debugPrint('Peripheral service already stopped');
      return;
    }

    await _stopGattServer();
    await _stopAdvertising();

    setState(() {
      _peripheralServiceRunning = false;
    });
  }

  void _startBleScanning() {
    _bleClient.initScan();

    setState(() {
      _bleScanning = true;
    });
  }

  void _stopBleScanning() {
    _bleClient.stopScan();

    setState(() {
      _bleScanning = false;
    });
  }

  void _startCentralService() {
    debugPrint('Starting central service');
    if (_centralServiceRunning) {
      debugPrint('Central service already running');
      return;
    }

    _startBleScanning();

    setState(() {
      _centralServiceRunning = true;
    });
  }

  void _stopCentralService() {
    debugPrint('Stopping central service');
    if (!_centralServiceRunning) {
      debugPrint('Central service already stopped');
      return;
    }

    _stopBleScanning();

    setState(() {
      _centralServiceRunning = false;
    });
  }

  Future<void> _startTracingService() async {
    if (_currentTracingMode == TracingMode.peripheral) {
      await _startPeripheralService();
    } else if (_currentTracingMode == TracingMode.central) {
      _startCentralService();
    }
  }

  Future<void> _stopTracingService() async {
    if (_currentTracingMode == TracingMode.peripheral) {
      await _stopPeripheralService();
    } else if (_currentTracingMode == TracingMode.central) {
      _stopCentralService();
    }
  }

  Future<void> _getContactStatus() async {
    String? contactStatus = await _contactUploadManager.getContactStatus();
    if (contactStatus == null) {
      // Set login status to false
      await _storage.setLoginStatus(false);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
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

  Future<void> _logout() async {
    Map<String, String>? tokens = await ServerAuth.getTokens();
    if (tokens == null) {
      // Tokens invalid
      debugPrint('Tokens invalid. Not refreshed.');
      if (mounted) {
        Utils.showSnackBar(context, 'Session expired', color: Colors.red);
      }

      // Delete temp IDs
      await _storage.deleteAllTempIds();

      // Delete tokens
      await _storage.deleteTokens();

      // Set login status to false
      await _storage.setLoginStatus(false);

      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
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
      // Stop tracing service
      await _stopTracingService();

      // Delete tokens from storage
      await _storage.deleteTokens();

      // Set login status to false
      await _storage.setLoginStatus(false);

      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Logout failed',
          color: Colors.red,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _checkAdvertisingSupport();

    if (kReleaseMode) {
      // Release mode
      // Start continuous tracing
      Future.doWhile(() async {
        _currentTracingMode = _tracingScheduler.getNext();
        await _startTracingService();
        await Future.delayed(const Duration(minutes: 1));
        await _stopTracingService();
        return true;
      });
    } else {
      // Debug mode
      _getDeviceInfo().then((value) {
        if (_deviceModel == 'SM-N920I') {
          // Peripheral
          _currentTracingMode = TracingMode.peripheral;
          _startPeripheralService();
        } else {
          // Central
          _currentTracingMode = TracingMode.central;
          _startCentralService();
        }
      });

      // Reset recent devices every 15 minutes
      Future.doWhile(() async {
        debugPrint('Clearing recent devices');
        _bleClient.clearRecentDevices();
        await Future.delayed(const Duration(minutes: 15));
        return true;
      });
    }

    // Register broadcast receiver for close contact count
    FBroadcast.instance().register(
      closeContactBroadcastKey,
      ((value, callback) {
        setState(() {
          _closeContactCount = value;
        });
      }),
    );

    // Wait for storage to be initialized
    Future.doWhile(() async {
      bool storageLoaded = _storage.isLoaded();

      if (storageLoaded) {
        // Get contact status
        _getContactStatus();

        // Get close contact count
        _storage.updateCloseContactCount();
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return !storageLoaded;
    });
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
              Navigator.pushNamed(context, '/upload'),
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
                  _logout();
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
          Navigator.pushNamed(context, '/scanner');
        },
        tooltip: 'Scan Building QR Code',
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _getContactStatus();
          _storage.updateCloseContactCount();
        },
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
                  Text(
                      'Advertisement Support: $_bleAdvertisementSupported'), // Central (Scanner/Client) controls
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
