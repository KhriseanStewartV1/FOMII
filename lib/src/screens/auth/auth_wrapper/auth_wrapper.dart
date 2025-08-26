import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/main_layout/main_layout.dart';
import 'package:fomo_connect/src/screens/auth/confirm_email/confirm_email_screen.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LoadingScreen());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return LogInScreen();
        }
        final user = snapshot.data;
        
        if (user!.emailVerified) {
          return MainLayout();
        } else {
          return ConfirmEmailScreen();
        }
      },
    );
  }
}
