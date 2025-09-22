import 'package:flutter/material.dart';

class LoadingSplashScreen extends StatelessWidget {
  final bool isStarting;
  const LoadingSplashScreen({super.key, required this.isStarting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: Image.asset("assets/fomo.png", width: 200, height: 200),
            ),
            const SizedBox(height: 200),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
