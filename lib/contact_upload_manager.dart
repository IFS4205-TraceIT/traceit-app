import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:traceit_app/const.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage/storage.dart';

class ContactUploadManager {
  final Storage _storage = Storage();

  Future<String?> getContactStatus() async {
    Map<String, String>? tokens = await ServerAuth.getTokens();
    if (tokens == null) {
      return null;
    }

    // Get contact status from server
    http.Response response = await http.get(
      Uri.parse(routeContactStatus),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${tokens['accessToken']}',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return http.Response('408 Request Timeout', 408);
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      String status = responseBody['status'];

      return status;
    } else {
      debugPrint(response.body);
      return 'Failed to get contact status';
    }
  }

  Future<bool?> getUploadStatus() async {
    Map<String, String>? tokens = await ServerAuth.getTokens();
    if (tokens == null) {
      return null;
    }

    // Get upload status from server
    debugPrint('Sending request to server to get upload status');
    http.Response response = await http.get(
      Uri.parse(routeContactUploadStatus),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${tokens['accessToken']}',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return http.Response('408 Request Timeout', 408);
      },
    );

    if (response.statusCode == 200) {
      // Received upload status
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      debugPrint('Upload status: ${responseBody['status']}');
      bool uploadStatus = responseBody['status'];
      return uploadStatus;
    } else {
      // Error requesting upload status
      debugPrint(response.body);
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadCloseContacts() async {
    // Get close contacts from storage
    List<dynamic> closeContacts = await _storage.getAllCloseContacts();

    List<Map<String, dynamic>> payload = closeContacts
        .map((contact) => {
              'temp_id': contact['tempId'],
              'rssi': contact['rssi'],
              'contact_timestamp': contact['timestamp'],
            })
        .toList();

    debugPrint('Payload: $payload');

    Map<String, String>? tokens = await ServerAuth.getTokens();
    if (tokens == null) {
      return {
        'uploaded': false,
        'message': 'Failed to get tokens',
      };
    }

    // Upload close contacts to server
    debugPrint('Uploading close contacts to server');

    http.Response response = await http
        .post(
      Uri.parse(routeContactUpload),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${tokens['accessToken']}',
      },
      body: jsonEncode({
        'temp_ids': payload,
      }),
    )
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return http.Response('408 Request Timeout', 408);
      },
    );

    if (response.statusCode == 201) {
      // Close contacts uploaded successfully
      debugPrint('Close contacts successfully uploaded');

      // Delete local close contacts data after upload
      debugPrint('Deleting close contact data on local storage');
      await _storage.deleteAllCloseContacts();

      return {
        'uploaded': true,
        'message': 'Close contacts successfully uploaded',
      };
    } else if (response.statusCode == 408) {
      return {
        'uploaded': false,
        'message': 'Request timeout',
      };
    } else {
      // Error uploading close contacts
      debugPrint(response.body);
      Map<String, dynamic> responseBody = jsonDecode(response.body);

      return {
        'uploaded': false,
        'message': responseBody['errors'][0],
      };
    }
  }
}
