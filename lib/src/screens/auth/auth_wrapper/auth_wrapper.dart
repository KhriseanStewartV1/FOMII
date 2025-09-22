import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/main_layout/main_layout.dart';
import 'package:fomo_connect/src/screens/auth/confirm_email/confirm_email_screen.dart';
import 'package:fomo_connect/src/screens/auth/get_tags_screen/get_tags.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/screens/loading_splash.dart/splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
    final user = AuthService().user;

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LoadingSplashScreen(isStarting: true));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return LogInScreen();
        }
        if (user!.emailVerified) {
          return FutureBuilder(
            future: UserServices().readUser(user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: LoadingSplashScreen(isStarting: true,));
              }
              final userDoc = snapshot.data!;
              if (userDoc.exists && userDoc.data()!.containsKey('tags')) {
                return MainLayout();
              }
              return GetTags();
            },
          );
        } else {
          return ConfirmEmailScreen();
        }
      },
    );
  }
}
