import 'package:flutter/material.dart';

class BuildingAccessScreen extends StatelessWidget {
  const BuildingAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String buildingName = args['buildingName'];
    final bool isInfected = args['isInfected'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Building Access'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: isInfected ? Colors.red : Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buildingName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isInfected ? 'Denied' : 'Allowed',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: 80,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
