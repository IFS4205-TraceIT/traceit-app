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
        child: Text(
          'Submitted',
          style: Theme.of(context)
              .textTheme
              .apply(
                fontSizeFactor: 0.6,
              )
              .headline1,
        ),
      ),
    );
  }
}
