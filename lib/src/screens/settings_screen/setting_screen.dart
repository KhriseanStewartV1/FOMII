import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/provider/dark_mode.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.check_outlined),
                title: Text("Goals"),
                onTap: () {
                  displayRoundedSnackBar(
                    context,
                    "Coming soon.\nKeep Posting and get Prepared",
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Provider.of<ThemeProvider>(context).isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                title: Text("Dark Theme"),
                trailing: Switch(
                  value: Provider.of<ThemeProvider>(context).isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme(value);
                    });
                  },
                ),
              ),
              ListTile(
                leading: Icon(Icons.logout_outlined, color: Colors.grey),
                title: Text(
                  "Sign Out",
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  await AuthService().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
