import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:traceit_app/screens/building_access/building_access_screen.dart';
import 'package:traceit_app/screens/building_access/scanner_screen.dart';
import 'package:traceit_app/screens/contact_upload_screen.dart';
import 'package:traceit_app/screens/tracing_screen.dart';
import 'package:traceit_app/screens/user_auth/login_screen.dart';
import 'package:traceit_app/screens/user_auth/totp_screen.dart';
import 'package:traceit_app/storage/storage_method_channel.dart';
import 'package:traceit_app/tempid/tempid_method_channel.dart';

void main() async {
  // Initialise Flutter Hive
  await Hive.initFlutter();

  runApp(const MyApp());

  // Configure method channels to native Android calls
  StorageMethodChannel.instance.configureChannel();
  TempIdMethodChannel.instance.configureChannel();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/totp': (context) => const TotpScreen(),
        '/tracing': (context) => const TracingScreen(),
        '/upload': (context) => const ContactUploadScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/building': (context) => const BuildingAccessScreen()
      },
    );
  }
}
