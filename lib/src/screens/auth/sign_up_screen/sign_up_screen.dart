import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/modal/user_modal.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _authpassword = TextEditingController();
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _loading = false;

  handleSubmit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final authpassword = _authpassword.text;
    final name = _name.text;

    if (_formKey.currentState!.validate() != false) {
      if (password == authpassword) {
        try {
          final check = await AuthService().createUser(
            context,
            email,
            password,
            name,
          );
          final uniqueId = await UserServices().generateUniqueId(
            name,
            checkUniqueIdExists,
          );
          final createUser = await UserServices().createUser(
            UserModal(
              userId: FirebaseAuth.instance.currentUser!.uid,
              name: name,
              profilePic: '',
              createdAt: DateTime.now(),
              email: email,
              bio: '',
              uniqueId: uniqueId,
            ),
          );

          if (check != null && createUser) {
            Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
          } else {
            displaySnackBar(context, "Creating user error");
          }
        } catch (e) {}
      } else {
        displaySnackBar(context, "Passwords aren't the same");
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
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
                  key: _formKey,
                  child: Column(
                    spacing: 20,
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(
                          icon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          labelText: 'Enter Username',
                        ),
                      ),
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
                      TextFormField(
                        controller: _authpassword,
                        decoration: InputDecoration(
                          icon: Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.visibility),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          labelText: 'Confirm Password',
                        ),
                      ),
                    ],
                  ),
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
                      "Sign up",
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
                    onPressed: () async {
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
                        Navigator.pushReplacementNamed(
                          context,
                          AppRouter.login,
                        );
                      },
                      child: Text(
                        "Log In!",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
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
