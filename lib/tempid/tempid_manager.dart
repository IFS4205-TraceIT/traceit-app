import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traceit_app/const.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage/storage.dart';

class TempIdManager {
  final Storage _storage = Storage();

  bool _isTempIdValid(Map<String, dynamic>? tempId) {
    if (tempId == null) {
      return false;
    }

    int epochNow = DateTime.now().millisecondsSinceEpoch ~/
        Duration.millisecondsPerSecond; // in seconds
    int epochStart = tempId['start'];
    int epochEnd = tempId['end'];
    return (epochNow >= epochStart) && (epochNow < epochEnd);
  }

  Future<String> getTempId() async {
    late Map<String, dynamic>? tempId;

    do {
      tempId = _storage.getOldestTempId();
      debugPrint('Temp ID: $tempId');

      if (tempId == null) {
        // No temp IDs available. Request new temp IDs from server.
        debugPrint('No temp IDs available. Request new temp IDs from server.');

        Map<String, String?> tokens = await _storage.getTokens();
        Map<String, String>? refreshedTokens =
            await ServerAuth.checkRefreshToken(
          tokens['accessToken']!,
          tokens['refreshToken']!,
        );

        if (refreshedTokens != null) {
          // Tokens not changed or refreshed
          // Save tokens
          await _storage.saveTokens(
            refreshedTokens['accessToken']!,
            refreshedTokens['refreshToken']!,
          );
        } else {
          // Tokens invalid
          debugPrint('Tokens invalid. Not refreshed.');

          // Delete tokens
          await _storage.deleteTokens();

          return '';
        }

        // Send request to server to get new temp IDs
        debugPrint('Send request to server to get new temp IDs');
        http.Response response = await http.get(
          Uri.parse('$serverUrl/contacts/temp_id'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${refreshedTokens['accessToken']}',
          },
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseBody = jsonDecode(response.body);
          List<Map<String, dynamic>> tempIds =
              List<Map<String, dynamic>>.from(responseBody['temp_ids']);
          int serverEpoch = responseBody['server_start_time'];
          // debugPrint('Temp IDs: $tempIds');

          tempId = tempIds[0];
          debugPrint('New temp ID: $tempId');

          // Save temp IDs
          debugPrint('Saving all temp IDs');
          _storage.saveTempIds(tempIds);
        } else {
          debugPrint(response.body);
          tempId = null;
          continue;
        }
      }

      if (!_isTempIdValid(tempId)) {
        debugPrint('Temp ID is not valid. Deleting it.');
        _storage.deleteOldestTempId();
      }
    } while (!_isTempIdValid(tempId));

    return tempId!['temp_id'];
  }
}
