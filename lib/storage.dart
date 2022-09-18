import 'dart:convert';

import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:traceit_app/const.dart';

class Storage {
  // Auth keys
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  // Close contact tracing keys
  static const String _boxEncryptionKey = 'key';
  static const String _closeContactBoxName = 'closeContact';
  static const String _closeContactCountKey = 'closeContactCount';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final Box<dynamic> _closeContactBox;
  int _closeContactCount = 0;

  Storage() {
    // Read box encryption key
    _secureStorage.read(key: _boxEncryptionKey).then((key) async {
      String? currKey = key;

      // Generate key if it doesn't exist
      if (currKey == null) {
        final List<int> newKey = Hive.generateSecureKey();
        currKey = base64Encode(newKey);

        await _secureStorage.write(
          key: _boxEncryptionKey,
          value: currKey,
        );
      }

      // Init Hive
      if (!Hive.isBoxOpen(_closeContactBoxName)) {
        String applicationDirectory =
            (await getApplicationDocumentsDirectory()).path;
        Hive.init(applicationDirectory);
      }

      // Open close contact secure Hive box
      _closeContactBox = await Hive.openBox(
        _closeContactBoxName,
        encryptionCipher: HiveAesCipher(base64Decode(currKey)),
      );

      // TODO: Remove for release
      // _secureStorage.delete(key: _closeContactCountKey);
      _closeContactBox.clear();
    });

    // TODO: Remove for release
    // Read close contact count
    // _secureStorage.read(key: _closeContactCountKey).then((count) {
    //   _closeContactCount = count == null ? 0 : int.parse(count);
    //   _broadcastCloseContactCount();
    // });
  }

  void _broadcastCloseContactCount() {
    FBroadcast.instance().stickyBroadcast(
      closeContactBroadcastKey,
      value: _closeContactCount,
    );
  }

  void _incrementCloseContactCount() async {
    _closeContactCount++;

    // Send broadcast to update UI
    _broadcastCloseContactCount();

    // TODO: Remove for release
    // await _secureStorage.write(
    //   key: _closeContactCountKey,
    //   value: _closeContactCount.toString(),
    // );
  }

  int get getCloseContactCount {
    return _closeContactCount;
  }

  Future<List<dynamic>> getAllCloseContacts() async {
    List<dynamic> closeContacts = _closeContactBox.values.toList();
    return closeContacts;
  }

  Future<void> writeCloseContact(String tempid, int rssi) async {
    Map<String, dynamic> closeContactData = {
      'tempid': tempid,
      'rssi': rssi,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _closeContactBox.add(closeContactData);

    _incrementCloseContactCount();
  }

  Future<Map<String, String?>> getTokens() async {
    String? accessToken = await _secureStorage.read(key: _accessTokenKey);
    String? refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    Map<String, String?> tokens = {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };

    return tokens;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }
}
