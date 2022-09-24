import 'package:flutter/material.dart';
import 'package:traceit_app/screens/login_screen.dart';
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
    return const MaterialApp(
      home: LoginScreen(),
    );
  }
}
