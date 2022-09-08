import 'package:flutter/services.dart';

class GattServer {
  /// Singleton instance
  static final GattServer _instance = GattServer._internal();

  /// Singleton factory
  factory GattServer() {
    return _instance;
  }

  /// Singleton constructor
  GattServer._internal();

  static const platform = MethodChannel('com.traceit_traceit_app/gatt');

  Future<bool> isRunning() async {
    try {
      return await platform.invokeMethod('isRunning');
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> start() async {
    try {
      await platform.invokeMethod('start');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> stop() async {
    try {
      await platform.invokeMethod('stop');
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
