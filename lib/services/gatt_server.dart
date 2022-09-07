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

  Future<void> startGattServer() async {
    try {
      await platform.invokeMethod('startGattServer');
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
