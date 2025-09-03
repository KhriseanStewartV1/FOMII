import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return; // Check if widget is still active
      if (user != null) {
        // User is signed in
        Navigator.pushReplacementNamed(context, AppRouter.mainLayout);
      } else {
        // Not signed in
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // Cancel the subscription to avoid leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
