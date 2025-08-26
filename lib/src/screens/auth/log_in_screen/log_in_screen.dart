import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/modal/user_modal.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  handleSubmit() {
    String email = _email.text.trim();
    String password = _password.text;

    if (_formKey.currentState?.validate() != false) {
      setState(() {
        _loading = true;
      });
      try {
        final check = AuthService().readUser(context, email, password);

        if (check == true) {
          Navigator.pushReplacementNamed(context, AppRouter.mainLayout);
        }
      } catch (e) {
        displaySnackBar(context, "Error: $e");
      } finally {
        setState(() {
          _loading = true;
        });
      }
    }
  }

  googleSignIn() async {
    try {
      bool check = await AuthService().signInWithGoogle(context);
      final uniqueId = await UserServices().generateUniqueId(
        FirebaseAuth.instance.currentUser!.displayName!,
        checkUniqueIdExists,
      );
      final createUser = await UserServices().createUser(
        UserModal(
          userId: FirebaseAuth.instance.currentUser!.uid,
          name: FirebaseAuth.instance.currentUser!.displayName!,
          profilePic: '',
          createdAt: DateTime.now(),
          email: FirebaseAuth.instance.currentUser!.email,
          bio: '',
          uniqueId: uniqueId,
        ),
      );
      if (check && createUser) {
        Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
      } else {
        displaySnackBar(context, "Error Happened");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //SVG
                Expanded(
                  child: Lottie.asset('assets/lottie/login.json', repeat: true),
                ),
                SizedBox(height: 30),
                Form(
                  child: Column(
                    spacing: 20,
                    children: [
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(
                          icon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          labelText: 'Enter Your Email',
                        ),
                      ),
                      TextFormField(
                        controller: _password,
                        decoration: InputDecoration(
                          icon: Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.visibility),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          labelText: 'Password',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(value: false, onChanged: (value) {}),
                        Text("Remember me?"),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
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
                    onPressed: _loading ? null : handleSubmit,
                    child: Text(
                      "LOG IN",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      _loading ? null : googleSignIn();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(Icons.g_mobiledata, size: 30),
                        Text(
                          "Google",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        _loading
                            ? null
                            : Navigator.pushReplacementNamed(
                                context,
                                AppRouter.signup,
                              );
                      },
                      child: Text(
                        "Sign Up!",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
