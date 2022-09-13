import 'package:flutter/material.dart';
import 'package:traceit_app/screens/tracing_screen.dart';
import 'package:traceit_app/storage_method_channel.dart';

void main() {
  runApp(const MyApp());
  StorageMethodChannel.instance.configureChannel();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TracingScreen(),
    );
  }
}
