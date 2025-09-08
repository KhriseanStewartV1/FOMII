import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  Timer? _timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AuthService().sendVerificationEmail(context);
    _startEmailVerificationCheck();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (_) async {
      bool verified = await AuthService().checkEmailVerified();
      if (verified) {
        _timer?.cancel(); // stop polling
        // Optionally, refresh user data
        await FirebaseAuth.instance.currentUser?.reload();
        // Navigate to main app or authWrapper
        Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // To adapt to theme (light/dark)
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Text
                Text(
                  'Verify Your Email',
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Instruction Text
                Text(
                  "We've sent a verification link to your email address. "
                  "Please check your inbox and follow the instructions "
                  "to verify your account. CHECK YOUR SPAM!!",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Illustration/Icon
                Icon(
                  Icons.email_outlined,
                  size: 120,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 32),
                // Resend Email Button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await AuthService().sendVerificationEmail(context);
                    },
                    child: Text(
                      "Resend to Email",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Continue Button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      final check = await AuthService().checkEmailVerified();
                      print(FirebaseAuth.instance.currentUser!.emailVerified);
                      if (check) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRouter.authWrapper,
                        );
                      } else {
                        displaySnackBar(context, "Email not Verified");
                      }
                    },
                    child: Text(
                      "Continue",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Optional: Change Email TextButton
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRouter.login);
                  },
                  child: const Text(
                    'Change Email',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
