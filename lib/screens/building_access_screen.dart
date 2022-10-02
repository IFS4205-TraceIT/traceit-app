import 'package:flutter/material.dart';

class BuildingAccessScreen extends StatelessWidget {
  const BuildingAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Building Access'),
      ),
      body: Center(
        child: Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            const Text('data'),
          ],
        ),
      ),
    );
  }
}
