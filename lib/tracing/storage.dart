import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class Storage {
  static const String boxEncryptionKey = 'key';
  static const String closeContactBoxName = 'closeContact';
  static const String closeContactCountKey = 'closeContactCount';

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late final Box<dynamic> closeContactBox;
  late int closeContactCount;

  Storage() {
    // Read box encryption key
    secureStorage.read(key: boxEncryptionKey).then((key) async {
      String? currKey = key;

      // Generate key if it doesn't exist
      if (currKey == null) {
        final List<int> newKey = Hive.generateSecureKey();
        currKey = base64Encode(newKey);

        await secureStorage.write(
          key: 'key',
          value: currKey,
        );
      }

      // Open close contact secure box
      closeContactBox = await Hive.openBox(
        closeContactBoxName,
        encryptionCipher: HiveAesCipher(base64Decode(currKey)),
      );
    });

    // Read close contact count
    secureStorage.read(key: closeContactCountKey).then((count) {
      closeContactCount = count == null ? 0 : int.parse(count);
    });
  }

  void _incrementCloseContactCount() async {
    closeContactCount++;

    await secureStorage.write(
      key: closeContactCountKey,
      value: closeContactCount.toString(),
    );
  }

  Future<int> getCloseContactCount() async {
    return closeContactCount;
  }

  Future<List<Map<String, dynamic>>> getAllCloseContacts() async {
    List<Map<String, dynamic>> closeContacts =
        closeContactBox.values.toList() as List<Map<String, dynamic>>;
    return closeContacts;
  }

  Future<void> writeCloseContact(String tempid, int rssi) async {
    Map<String, dynamic> closeContactData = {
      'tempid': tempid,
      'rssi': rssi,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await closeContactBox.add(closeContactData);

    _incrementCloseContactCount();
  }
}
