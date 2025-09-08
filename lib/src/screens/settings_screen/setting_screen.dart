import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/provider/dark_mode.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/widgets/default_card.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
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
  final user = AuthService().user; // FirebaseAuth.instance.currentUser
  final isAnonymous = AuthService().user?.isAnonymous ?? true;
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Stack(
            children: [
              Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.check_outlined),
                    title: Text("Goals"),
                    onTap: () {
                      showGoals();
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
              Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: StreamBuilder(
                  stream: UserServices().userStream(uid),
                  builder: (context, async) {
                    if(async.connectionState == ConnectionState.waiting){
                      return Center(child: LoadingScreen(),);
                    }
                    if(!async.hasData || async.data == null){
                      return LogInScreen();
                    }
                    if(isAnonymous){
                      return ListTile(leading: DefaultCard(), title: Text("Anonymous"), trailing: IconButton(onPressed: () {
                      showAccountManager();
                    }, icon: Icon(Icons.arrow_drop_down_circle_outlined)),);
                    }
                    final data = async.data;
                    return ListTile(leading: CircleAvatar(backgroundImage: NetworkImage(data!['profilePic'])), title: Text("${data['name']}"), trailing: IconButton(onPressed: () {
                      showAccountManager();
                    }, icon: Icon(Icons.arrow_drop_up_outlined, size: 30,)),);
                  }
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  showGoals(){
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        checkPosts() async {
          if (user == null || isAnonymous) {
            displayRoundedSnackBar(context, "Sign in to track your goals");
            return;
          }

          final postStream = PostServices().readYourPosts(uid);
          final posts = await postStream.first; // get first snapshot from stream

          // if posts are PostModal objects
          final userPosts = posts.where((post) => post.userId == user!.uid).toList();

          print("User has ${userPosts.length} posts");

          if(userPosts.length >= 10){
            displayRoundedSnackBar(context, "Congratulations! You've reached 10 posts!");
            UserServices().updateUser({'badges': FieldValue.arrayUnion(['10_posts'])});
          }
          if(userPosts.length >= 50){
            displayRoundedSnackBar(context, "Amazing! You've reached 100 posts!");
            UserServices().updateUser({'badges': FieldValue.arrayUnion(['100_posts'])});
          }
          if(userPosts.length >= 100){
            displayRoundedSnackBar(context, "Incredible! You've reached 100 followers!");
            UserServices().updateUser({'badges': FieldValue.arrayUnion(['100_followers'])});
          }
          UserServices().updateUser({'badges': FieldValue.arrayUnion(['tester'])});
        }
        checkPosts();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.check_outlined),
                title: Text("Goals"),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.star_border),
                title: Text("Reach 10 posts"),
                subtitle: Text("Keep posting and engaging with the community to reach this goal."),
                onTap: checkPosts,
              ),
              ListTile(
                leading: Icon(Icons.star_half),
                title: Text("Reach 100 posts"),
                subtitle: Text("Stay active and contribute to the community to achieve this milestone."),
              ),
              ListTile(
                leading: Icon(Icons.follow_the_signs),
                title: Text("Reach 100 Followers"),
                subtitle: Text("Become a top contributor by consistently sharing valuable content."),
              ),
            ],
          ),
        );
      },
    );
  }

  showAccountManager() {
  return showModalBottomSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Icon(isAnonymous ? Icons.person_outline : Icons.person),
              ),
              title: Text(isAnonymous ? "Anonymous Account" : "Signed in as ${user?.email ?? user?.uid}"),
            ),
            const Divider(),
            if (isAnonymous)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text("Sign in with Account"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRouter.login);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.person_off),
                title: const Text("Switch to Anonymous"),
                onTap: () async {
                  await AuthService().signOut();
                  await AuthService().signInAnonymous(context);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      );
    },
  );
}

}
