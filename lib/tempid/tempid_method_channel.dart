import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:traceit_app/tempid/tempid_manager.dart';

class TempIdMethodChannel {
  static const _channelNameTempId = 'com.traceit.traceit_app/tempid';
  late MethodChannel _methodChannel;

  final TempIdManager _tempIdManager = TempIdManager();

  static final TempIdMethodChannel instance = TempIdMethodChannel._init();
  TempIdMethodChannel._init();

  void configureChannel() {
    _methodChannel = const MethodChannel(_channelNameTempId);
    _methodChannel.setMethodCallHandler(_methodHandler);
  }

  Future<String> _methodHandler(MethodCall call) async {
    switch (call.method) {
      case 'getTempId':
        return _tempIdManager.getTempId();
      default:
        debugPrint('No method handler for method ${call.method}');
        throw MissingPluginException();
    }
  }
}
