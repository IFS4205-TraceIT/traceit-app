import 'dart:convert';

import 'package:fbroadcast/fbroadcast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:traceit_app/const.dart';

class Storage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Auth keys
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  // Temp ID
  static const String _tempIdBoxIndexKey = 'tempIdBoxKey';
  static const String _tempIdBoxName = 'tempId';
  late final Box<dynamic> _tempIdBox;

  // Close contact
  static const String _closeContactBoxIndexKey = 'closeContactBoxKey';
  static const String _closeContactBoxName = 'closeContact';
  static const String _closeContactCountKey = 'closeContactCount';
  late final Box<dynamic> _closeContactBox;
  int _closeContactCount = 0;

  Storage() {
    _initTempidBox();
    _initCloseContactBox();
  }

  void _initTempidBox() async {
    // Read close contact box encryption key
    String? tempIdBoxKey = await _secureStorage.read(
      key: _tempIdBoxIndexKey,
    );

    // Generate key if it doesn't exist
    if (tempIdBoxKey == null) {
      final List<int> newKey = Hive.generateSecureKey();
      tempIdBoxKey = base64Encode(newKey);

      await _secureStorage.write(
        key: _tempIdBoxIndexKey,
        value: tempIdBoxKey,
      );
    }

    // Init Hive
    if (!Hive.isBoxOpen(_tempIdBoxName)) {
      String applicationDirectory =
          (await getApplicationDocumentsDirectory()).path;
      Hive.init(applicationDirectory);
    }

    // Open close contact secure Hive box
    _tempIdBox = await Hive.openBox(
      _tempIdBoxName,
      encryptionCipher: HiveAesCipher(base64Decode(tempIdBoxKey)),
    );
  }

  void _initCloseContactBox() async {
    // Read close contact box encryption key
    String? closeContactBoxKey = await _secureStorage.read(
      key: _closeContactBoxIndexKey,
    );

    // Generate key if it doesn't exist
    if (closeContactBoxKey == null) {
      final List<int> newKey = Hive.generateSecureKey();
      closeContactBoxKey = base64Encode(newKey);

      await _secureStorage.write(
        key: _closeContactBoxIndexKey,
        value: closeContactBoxKey,
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
      encryptionCipher: HiveAesCipher(base64Decode(closeContactBoxKey)),
    );

    // TODO: Uncomment for release
    // Read close contact count
    // _secureStorage.read(key: _closeContactCountKey).then((count) {
    //   _closeContactCount = count == null ? 0 : int.parse(count);
    //   _broadcastCloseContactCount();
    // });
  }

  /* Auth token */
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

  Future<void> deleteTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  /* Temp Id */
  Map<String, dynamic>? getOldestTempId() {
    if (_tempIdBox.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(_tempIdBox.getAt(0));
  }

  void deleteOldestTempId() {
    if (_tempIdBox.isEmpty) {
      return;
    }

    _tempIdBox.deleteAt(0);
  }

  void saveTempIds(List<Map<String, dynamic>> tempIds) {
    _tempIdBox.addAll(tempIds);
  }

  /* Close contact */
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

  List<dynamic> getAllCloseContacts() {
    List<dynamic> closeContacts = _closeContactBox.values.toList();
    return closeContacts;
  }

  Future<void> writeCloseContact(String tempId, int rssi) async {
    Map<String, dynamic> closeContactData = {
      'tempId': tempId,
      'rssi': rssi,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _closeContactBox.add(closeContactData);

    _incrementCloseContactCount();
  }
}
