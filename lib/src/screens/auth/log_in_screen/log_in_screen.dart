import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/modal/user_modal.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool showPassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadEmail();
  }

  void _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _email.text = prefs.getString('email') ?? '';
      }
    });
  }

  handleSubmit() async {
    String email = _email.text.trim();
    String password = _password.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loading = true;
    });
    if (_formKey.currentState?.validate() != false) {
      try {
        final check = await AuthService().loginUser(context, email, password);
        if (check != null) {
          if (_rememberMe) {
            await prefs.setBool('remember_me', true);
            await prefs.setString('email', _email.text);
          } else {
            await prefs.remove('remember_me');
            await prefs.remove('email');
          }
          Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
        }
      } catch (e) {
        displaySnackBar(context, "Error: ${e}");
        setState(() {
          _loading = false;
        });
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  googleSignIn() async {
    try {
      UserCredential? userCredential = await AuthService().signInWithGoogle(
        context,
      );
      if (userCredential != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        displayRoundedSnackBar(
          context,
          "By Signing Up You Agree to the Terms and Conditions!",
        );
        if (!userDoc.exists) {
          //create user in firestore
          final user = FirebaseAuth.instance.currentUser!;
          final uniqueId = await UserServices().generateUniqueId(
            user.displayName!,
            checkUniqueIdExists,
          );

          final createUser = await UserServices().createUser(
            UserModal(
              userId: user.uid,
              name: user.displayName!,
              profilePic: '',
              createdAt: DateTime.now(),
              email: user.email,
              bio: '',
              uniqueId: uniqueId,
              terms: true,
            ),
          );

          if (createUser == true) {
            Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
          } else {
            displaySnackBar(context, "Failed to create user");
          }
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.authWrapper);
        }
      } else {
        displaySnackBar(context, "Google sign-in failed");
      }
    } catch (e) {
      print(e);
      displaySnackBar(context, "Error: $e");
    }
  }

  hidePassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //SVG
                Expanded(child: Image.asset("assets/fomo.png")),
                SizedBox(height: 30),
                Form(
                  child: Column(
                    spacing: 20,
                    children: [
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.email),
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextFormField(
                        controller: _password,
                        obscureText: showPassword,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: hidePassword,
                            icon: Icon(
                              !showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
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
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.forgotPassword,
                      ),
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                        ),
                        Text("Remember me?", style: TextStyle(fontSize: 13)),
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
                      spacing: 20,
                      children: [
                        Icon(Bootstrap.google, size: 23),
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
