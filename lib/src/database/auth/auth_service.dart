import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/screens/auth/telephone_screen/verify_otp_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_sign_in/google_sign_in.dart';

final _instance = FirebaseAuth.instance;
// final _googleSignIn = GoogleSignIn.instance;

class AuthService {
  Future<UserCredential?> createUser(
    BuildContext context,
    String email,
    String password,
    String name,
  ) async {
    try {
      final cred = await _instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _instance.currentUser!.updateDisplayName(name);
      return cred;
    } on FirebaseAuthException catch (e) {
      String errorMsg = e.message ?? e.code;
      displayRoundedSnackBar(context, errorMsg);
      print('Error in createUser: $e');
      return null;
    } catch (e) {
      displayRoundedSnackBar(context, 'An unexpected error occurred.');
      print('Unexpected error in createUser: $e');
      return null;
    }
  }

  Future<UserCredential?> readUser(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      UserCredential user = await _instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user;
    } on FirebaseAuthException catch (e) {
      displayFloatingSnackBar(context, "Error: $e");
      return null;
    }
  }

  Future<void> sendVerificationEmail(context) async {
    User? user = _instance.currentUser;

    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        displaySnackBar(context, 'Verification email sent.');
      } catch (e) {
        print(e);
      }
    }
  }

  Future<bool> checkEmailVerified() async {
    User? user = _instance.currentUser;
    if (user != null) {
      await user.reload(); // Refresh user data from Firebase
      return user.emailVerified;
    }
    return false;
  }

  Future<void> sendCode(String phoneNumber, BuildContext context) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval (sometimes works on Android)
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        displayRoundedSnackBar(context, "Verification failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(
              verificationId: verificationId,
              telephone: phoneNumber,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }


  Future<PhoneAuthCredential?> verifyTelephone(
    BuildContext context,
    String verificationId,
    String smsCode,
    String telephone,
  ) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _instance.currentUser!.linkWithCredential(cred);

      await UserServices().updateUser({"telephone": telephone});

      return cred;
    } catch (e) {
      displayRoundedSnackBar(context, "Incorrect code or number");
      return null;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkResetPassword(String code, String newPassword) async {
    await _instance.confirmPasswordReset(code: code, newPassword: newPassword);
  }

  Future<void> signOut() async {
    await _instance.signOut();
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
          

      displayRoundedSnackBar(
        context,
        "Signed in: ${userCredential.user?.displayName}",
      );
      return userCredential;
    } catch (e) {
      displayRoundedSnackBar(context, "Error Signing in With Google: $e");
      return null;
    }
  }

  User? user = _instance.currentUser;
}
