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

    int epochNow = DateTime.now().millisecondsSinceEpoch;
    int epochStart = tempId['start'];
    int epochEnd = tempId['end'];
    return epochNow >= epochStart && epochNow < epochEnd;
  }

  Future<String> getTempId() async {
    late Map<String, dynamic>? tempId;

    // TODO: Remove hardcoded value
    return '4qS6+bFwTVhFNLeme/N2DMkAN2l6NgtbCELmPOict0/l0PmmGpkNliB8RicVjEZxWxtjFofUUNZCkUJrbEYAqyA1t7zCQGmfHQPEO5+M2VBeRJCOgEmeVeQE97FKFtvTVA==';

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

        // TODO: Test with server response
        http.Response response = await http.get(
          Uri.parse('$serverUrl/tempids'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${refreshedTokens!['accessToken']}',
          },
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseBody = jsonDecode(response.body);
          List<Map<String, dynamic>> tempIds = responseBody['tempIds'];
          debugPrint('Temp IDs: $tempIds');

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

    return tempId!['tempId'];
  }
}
