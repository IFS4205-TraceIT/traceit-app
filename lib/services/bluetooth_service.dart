import 'dart:async';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:traceit_app/services/peripheral_service.dart';

import 'central_service.dart';

Future<FlutterBackgroundService> initialiseBluetoothService() async {
  final bluetoothService = FlutterBackgroundService();

  await bluetoothService.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  bluetoothService.startService();

  return bluetoothService;
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Background task

  // Timer.periodic(const Duration(seconds: 10), (timer) async {
  //   DateTime datetime = DateTime.now();

  //   if (service is AndroidServiceInstance) {
  //     service.setForegroundNotificationInfo(
  //       title: "Scanning for close contacts",
  //       content: "$datetime ${datetime.millisecondsSinceEpoch}",
  //     );
  //   }

  //   // Invoke function example
  //   // service.invoke(
  //   //   'update',
  //   //   {
  //   //     "current_date": DateTime.now().toIso8601String(),
  //   //   },
  //   // );
  // });

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  print('Running on ${androidInfo.model}');

  if (androidInfo.model == 'SM-N920I') {
    // Peripheral
    test_peripheral_service(service);
  } else {
    // Central
    test_central_service(service);
  }
}
