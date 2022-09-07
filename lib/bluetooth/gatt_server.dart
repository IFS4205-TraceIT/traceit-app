import 'package:flutter/services.dart';

class GattServer {
  // Singleton instance
  static final GattServer _instance = GattServer._internal();

  // Singleton factory
  factory GattServer() {
    return _instance;
  }

  // Singleton constructor
  GattServer._internal();

  // Method channel for communicating with native code
  static const _methodChannel = MethodChannel('com.example.traceit_app/method');

  Future<bool> start() async {
    try {
      return await _methodChannel.invokeMethod('start');
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stop');
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
