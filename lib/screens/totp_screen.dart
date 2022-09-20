import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:traceit_app/screens/tracing_screen.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_screen.dart';

class TotpScreen extends StatefulWidget {
  const TotpScreen({
    super.key,
    required this.hasOtp,
    required this.tempAccessToken,
    required this.tempRefreshToken,
  });

  final bool hasOtp;
  final String tempAccessToken;
  final String tempRefreshToken;

  @override
  State<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends State<TotpScreen> {
  final Storage _storage = Storage();

  bool _hasGeneratedQrCode = false;

  late String _tempAccessToken;
  late String _tempRefreshToken;

  String _qrCode = '';
  String _otpauthUrl = '';

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> registerTotp() async {
    // Check if tokens need to be refreshed
    Map<String, String>? refreshedTokens = await ServerAuth.checkRefreshToken(
      _tempAccessToken,
      _tempRefreshToken,
    );

    if (refreshedTokens != null) {
      setState(() {
        _tempAccessToken = refreshedTokens['accessToken']!;
        _tempRefreshToken = refreshedTokens['refreshToken']!;
      });
    } else {
      // Tokens invalid
      debugPrint('Tokens invalid. Not refreshed.');
      showSnackbar('Session expired');

      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    // Request for TOTP QR code
    Response response = await ServerAuth.totpRegister(_tempAccessToken);

    Map<String, dynamic> responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      String qrCode = responseBody['barcode'] as String;
      String otpauthUrl = responseBody['url'] as String;
      debugPrint('QR Code: $qrCode');
      debugPrint('OTPAuth URL: $otpauthUrl');

      setState(() {
        _hasGeneratedQrCode = true;
        _qrCode = qrCode;
        _otpauthUrl = otpauthUrl;
      });
    } else {
      debugPrint(response.body);
      showSnackbar('Failed to generate TOTP QR code!');
    }
  }

  Future<void> openInTotpApp() async {
    debugPrint(_otpauthUrl);

    bool launchedTotpApp = await launchUrl(Uri.parse(_otpauthUrl));
    if (!launchedTotpApp) {
      debugPrint('Failed to open TOTP app!');
      showSnackbar('Failed to open TOTP app!');
    }
  }

  @override
  void initState() {
    super.initState();
    _tempAccessToken = widget.tempAccessToken;
    _tempRefreshToken = widget.tempRefreshToken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hasOtp ? 'TOTP Login' : 'TOTP Registration'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                // No TOTP registered
                visible: !widget.hasOtp,
                child: Wrap(
                  direction: Axis.vertical,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 20,
                  children: [
                    const Text(
                      'Register your TOTP',
                      style: TextStyle(fontSize: 20),
                    ),
                    Visibility(
                      // TOTP reistration
                      visible: !widget.hasOtp,
                      child: Column(
                        children: [
                          Visibility(
                            visible: !_hasGeneratedQrCode,
                            child: ElevatedButton(
                              onPressed: registerTotp,
                              child: const Text('Generate QR Code'),
                            ),
                          ),
                          Visibility(
                            visible: _hasGeneratedQrCode,
                            child: Wrap(
                              direction: Axis.vertical,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              children: [
                                Image.memory(
                                  base64Decode(_qrCode),
                                  width: 200,
                                  height: 200,
                                ),
                                const Text(
                                  'Scan the QR code above to save the TOTP',
                                ),
                                const Text(
                                  'OR',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(
                                  width: 300,
                                  child: Text(
                                    'Automatically add a TOTP account to your '
                                    'TOTP app by pressing the button below.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: openInTotpApp,
                                  child: const Text('Open in TOTP app'),
                                ),
                                TotpLogin(
                                  tempAccessToken: _tempAccessToken,
                                  tempRefreshToken: _tempRefreshToken,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                // TOTP login
                visible: widget.hasOtp,
                child: Center(
                  child: Wrap(
                    direction: Axis.vertical,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    children: [
                      const Text(
                        'Enter your TOTP Code',
                        style: TextStyle(fontSize: 20),
                      ),
                      TotpLogin(
                        tempAccessToken: _tempAccessToken,
                        tempRefreshToken: _tempRefreshToken,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TotpLogin extends StatefulWidget {
  const TotpLogin({
    super.key,
    required this.tempAccessToken,
    required this.tempRefreshToken,
  });

  final String tempAccessToken;
  final String tempRefreshToken;

  @override
  State<TotpLogin> createState() => _TotpLoginState();
}

class _TotpLoginState extends State<TotpLogin> {
  final Storage _storage = Storage();
  final _totpTextController = TextEditingController();

  late String _tempAccessToken;
  late String _tempRefreshToken;

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> totpLogin() async {
    String totpCode = _totpTextController.text;
    debugPrint('TOTP code: $totpCode');

    if (totpCode.isEmpty) {
      showSnackbar('Please enter your TOTP code!');
      return;
    }

    // Check if tokens need to be refreshed
    Map<String, String>? refreshedTokens = await ServerAuth.checkRefreshToken(
      _tempAccessToken,
      _tempRefreshToken,
    );

    if (refreshedTokens != null) {
      setState(() {
        _tempAccessToken = refreshedTokens['accessToken']!;
        _tempRefreshToken = refreshedTokens['refreshToken']!;
      });
    } else {
      // Tokens invalid
      debugPrint('Tokens invalid. Not refreshed.');
      showSnackbar('Session expired');

      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    // Send TOTP code to server
    Response response = await ServerAuth.totpLogin(
      _tempAccessToken,
      totpCode,
    );

    Map<String, dynamic> responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      String accessToken = responseBody['access'] as String;
      String refreshToken = responseBody['refresh'] as String;
      debugPrint('Access token: $accessToken');
      debugPrint('Refresh token: $refreshToken');

      // Save access token to shared preferences
      _storage.saveTokens(accessToken, refreshToken);

      // Navigate to tracing screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const TracingScreen(),
          ),
        );
      }
    } else {
      debugPrint(response.body);
      showSnackbar('Failed to login with TOTP!');
    }
  }

  @override
  void initState() {
    super.initState();
    _tempAccessToken = widget.tempAccessToken;
    _tempRefreshToken = widget.tempAccessToken;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _totpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            keyboardType: TextInputType.number,
            maxLength: 6,
            controller: _totpTextController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'TOTP Code',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: totpLogin,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
