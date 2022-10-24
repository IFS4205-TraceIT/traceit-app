import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/storage/storage.dart';
import 'package:traceit_app/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class TotpScreen extends StatefulWidget {
  const TotpScreen({super.key});

  @override
  State<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends State<TotpScreen> {
  late bool _hasOtp;

  bool _hasGeneratedQrCode = false;

  String _tempAccessToken = '';
  String _tempRefreshToken = '';

  String _qrCode = '';
  String _otpauthUrl = '';

  Future<void> registerTotp() async {
    // Request for TOTP QR code
    Map<String, dynamic>? totpRegistration =
        await ServerAuth.totpRegister(_tempAccessToken);
    if (totpRegistration == null) {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Failed to generate TOTP QR code!',
          color: Colors.red,
        );
      }

      return;
    }

    setState(() {
      _hasGeneratedQrCode = totpRegistration['hasGeneratedQrCode'];
      _qrCode = totpRegistration['qrCode'];
      _otpauthUrl = totpRegistration['otpauthUrl'];
    });
  }

  Future<void> openInTotpApp() async {
    debugPrint(_otpauthUrl);

    bool launchedTotpApp = await launchUrl(Uri.parse(_otpauthUrl));
    if (!launchedTotpApp) {
      debugPrint('Failed to open TOTP app!');
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Failed to open TOTP app!',
          color: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      _hasOtp = args['hasOtp'];
      _tempAccessToken = args['tempAccessToken'];
      _tempRefreshToken = args['tempRefreshToken'];
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_hasOtp ? 'TOTP Login' : 'TOTP Registration'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                // No TOTP registered
                visible: !_hasOtp,
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
                      // TOTP registration
                      visible: !_hasOtp,
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
                visible: _hasOtp,
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

  Future<void> totpLogin() async {
    String totpCode = _totpTextController.text;
    // debugPrint('TOTP code: $totpCode');

    if (totpCode.isEmpty) {
      Utils.showSnackBar(
        context,
        'Please enter your TOTP code!',
        color: Colors.red,
      );
      return;
    }

    // Send TOTP code to server
    bool totpLoggedIn = await ServerAuth.totpLogin(
      _tempAccessToken,
      totpCode,
    );

    if (!totpLoggedIn) {
      if (mounted) {
        Utils.showSnackBar(
          context,
          'Failed to login with TOTP!',
          color: Colors.red,
        );
      }

      return;
    }

    // Set login status
    await _storage.setLoginStatus(true);

    // Navigate to Tracing Screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/tracing');
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
