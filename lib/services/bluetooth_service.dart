import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

Future<FlutterBackgroundService> initialiseBluetoothService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  service.startService();

  return service;
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

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    DateTime datetime = DateTime.now();

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Scanning for close contacts",
        content: "$datetime ${datetime.millisecondsSinceEpoch}",
      );
    }
    // service.invoke(
    //   'update',
    //   {
    //     "current_date": DateTime.now().toIso8601String(),
    //   },
    // );
  });
}
