import 'package:flutter/material.dart';
import 'package:traceit_app/screens/building_access_screen.dart';
import 'package:traceit_app/screens/contact_upload_screen.dart';
import 'package:traceit_app/screens/tracing_screen.dart';
import 'package:traceit_app/screens/user_auth/login_screen.dart';
import 'package:traceit_app/storage/storage_method_channel.dart';
import 'package:traceit_app/tempid/tempid_method_channel.dart';

void main() {
  runApp(const MyApp());
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
        '/tracing': (context) => const TracingScreen(),
        '/contact_upload': (context) => const ContactUploadScreen(),
        '/building_access': (context) => const BuildingAccessScreen()
      },
    );
  }
}
