import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:traceit_app/const.dart';
import 'package:traceit_app/storage.dart';

class ServerAuth {
  static Future<http.Response> register(
    String username,
    String password,
    String email,
    String phoneNumber,
  ) async {
    http.Response response = await http.post(
      Uri.parse('$serverUrl/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
        'email': email,
        'phone_number': phoneNumber,
      }),
    );

    return response;
  }

  static Future<http.Response> login(String username, String password) async {
    http.Response response = await http.post(
      Uri.parse('$serverUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    return response;
  }

  static Future<Map<String, String>?> checkRefreshToken(
    String accessToken,
    String refreshToken,
  ) async {
    bool hasAccessTokenExpired = JwtDecoder.isExpired(accessToken);
    bool hasRefreshTokenExpired = JwtDecoder.isExpired(refreshToken);

    if (!hasAccessTokenExpired) {
      return {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
    } else if (hasAccessTokenExpired && !hasRefreshTokenExpired) {
      // Refresh tokens
      http.Response response = await ServerAuth.refreshToken(refreshToken);

      if (response.statusCode == 200) {
        debugPrint('Tokens refreshed');
        Map<String, dynamic> responseBody = await jsonDecode(response.body);
        return {
          'accessToken': responseBody['access'] as String,
          'refreshToken': responseBody['refresh'] as String,
        };
      } else {
        debugPrint(response.body);
        return null;
      }
    } else if (hasAccessTokenExpired && hasRefreshTokenExpired) {
      debugPrint('Refresh token expired');
      return null;
    }

    debugPrint('Tokens invalid');
    return null;
  }

  static Future<http.Response> refreshToken(String refreshToken) async {
    http.Response response = await http.post(
      Uri.parse('$serverUrl/auth/refresh'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'refresh': refreshToken,
      }),
    );

    return response;
  }

  static Future<http.Response> logout() async {
    // Get tokens from storage
    final Storage storage = Storage();
    Map<String, String?> tokens = await storage.getTokens();

    http.Response response = await http.post(
      Uri.parse('$serverUrl/auth/logout'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${tokens['accessToken']}',
      },
      body: jsonEncode(<String, String?>{
        'refresh': tokens['refreshToken'],
      }),
    );

    return response;
  }

  static Future<http.Response> totpRegister(String tempAccessToken) async {
    http.Response response = await http.post(
      Uri.parse('$serverUrl/auth/totp/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $tempAccessToken',
      },
    );

    return response;
  }

  static Future<http.Response> totpLogin(
    String tempAccessToken,
    String totpCode,
  ) async {
    http.Response response = await http.post(
      Uri.parse('$serverUrl/auth/totp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $tempAccessToken',
      },
      body: jsonEncode(<String, String>{
        'totp': totpCode,
      }),
    );

    return response;
  }
}
