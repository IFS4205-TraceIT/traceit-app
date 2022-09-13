import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traceit_app/storage.dart';

class StorageMethodChannel {
  static const _channelNameStorage = 'com.traceit.traceit_app/storage';
  late MethodChannel _methodChannel;

  final Storage storage = Storage();

  static final StorageMethodChannel instance = StorageMethodChannel._init();
  StorageMethodChannel._init();

  void configureChannel() {
    _methodChannel = const MethodChannel(_channelNameStorage);
    _methodChannel.setMethodCallHandler(this._methodHandler);
  }

  Future<void> _methodHandler(MethodCall call) async {
    final arguments = call.arguments;

    switch (call.method) {
      case 'writeCloseContact':
        await storage.writeCloseContact(arguments['tempid'], arguments['rssi']);
        break;
      default:
        debugPrint('No method handler for method ${call.method}');
        throw MissingPluginException();
    }
  }
}
