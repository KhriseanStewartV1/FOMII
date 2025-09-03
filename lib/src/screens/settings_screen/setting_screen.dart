import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/provider/dark_mode.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationsEnabled = false; // Placeholder for notification setting
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled =
          prefs.getBool("notifications_enabled") ??
          true; // Replace with actual loading logic
    });
  }

  Future<void> _saveNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notifications_enabled", value);
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      bool granted = await NotificationService()
          .requestNotificationPermission();
      if (granted) {
        setState(() => _notificationsEnabled = true);
        await _saveNotificationPref(true);
        displayRoundedSnackBar(context, "Notifications enabled");
      } else {
        displayRoundedSnackBar(context, "Permission denied");
      }
    } else {
      setState(() => _notificationsEnabled = false);
      await _saveNotificationPref(false);
      displayRoundedSnackBar(context, "Notifications disabled");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
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
                  _notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                ),
                title: Text("Notifications"),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
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
                  Navigator.pushReplacementNamed(context, AppRouter.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
