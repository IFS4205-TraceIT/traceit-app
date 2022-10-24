import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loader_overlay/loader_overlay.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:traceit_app/const.dart';
import 'package:traceit_app/server_auth.dart';
import 'package:traceit_app/utils.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;

  Future<void> submitBuildingAccess(String buildingId) async {
    Map<String, String>? tokens = await ServerAuth.getTokens();
    if (tokens == null) {
      // Token invalid, navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    http.Response response = await http
        .post(
      Uri.parse(routeBuildingAccessRegister),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${tokens['accessToken']}',
      },
      body: jsonEncode({
        'building': buildingId,
      }),
    )
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return http.Response('408 Request Timeout', 408);
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Request successful
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      String buildingName = responseJson['building_name'];
      bool isInfected = responseJson['infected'];

      if (mounted) {
        Navigator.popAndPushNamed(
          context,
          '/building',
          arguments: {
            'buildingName': buildingName,
            'isInfected': isInfected,
          },
        );
      }
    } else {
      // Request error, show error message
      debugPrint(response.body);

      if (mounted) {
        Utils.showSnackBar(
          context,
          'Failed to submit building access',
          color: Colors.red,
        );

        Navigator.pop(context);
      }

      context.loaderOverlay.hide();
      _controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    _controller!.resumeCamera();

    controller.scannedDataStream.listen((scanData) {
      BarcodeFormat codeFormat = scanData.format;
      String? codeData = scanData.code;
      debugPrint('$codeFormat $codeData');

      if (codeData != null) {
        _controller!.pauseCamera();
        context.loaderOverlay.show();

        submitBuildingAccess(codeData);
      }
    });
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller!.pauseCamera();
    } else if (Platform.isIOS) {
      _controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoaderOverlay(
        child: QRView(
          key: _qrKey,
          formatsAllowed: const [BarcodeFormat.qrcode],
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: 300,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
