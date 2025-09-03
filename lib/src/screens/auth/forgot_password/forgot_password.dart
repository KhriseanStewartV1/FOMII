import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _sendPasswordReset() async {
    final email = _emailController.text;
    if (email.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await AuthService().resetPassword(_emailController.text);
        displayRoundedSnackBar(context, "Password reset sent to email");
      } on FirebaseAuthException catch (e) {
        displaySnackBar(context, e.message!);
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      displayRoundedSnackBar(context, "Enter your email");
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // Header
                Text(
                  'Forgot Password',
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Instruction
                Text(
                  "Enter your email address below and we'll send you "
                  "a link to reset your password.",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Illustration/Icon
                Icon(
                  Icons.lock_outline,
                  size: 120,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 32),
                // Email TextField
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),
                // Send Reset Email Button
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
                    onPressed: _isLoading ? null : _sendPasswordReset,
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : Text(
                            "Send Reset Email",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Back to Login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Back to Login',
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
