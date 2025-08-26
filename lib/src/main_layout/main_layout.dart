import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/screens/home_screen/home_screen.dart';
import 'package:fomo_connect/src/screens/inbox_screen/inbox_screen.dart';
import 'package:fomo_connect/src/screens/profile_screen/profile_screen.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

List<Widget> _screens = [HomeScreen(), InboxScreen(), ProfileScreen()];

class _MainLayoutState extends State<MainLayout> {
  int currentIndex = 0;
  ontap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    checker();
  }

  void checker() async {
    final displayName = await FirebaseAuth.instance.currentUser!.displayName;
    displayRoundedSnackBar(context, "Signed in as $displayName");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, s) {
        if (!s.hasData) {
          return Center(child: LoadingScreen());
        }
        final user = s.data;
        if (user == null) {
          return LogInScreen();
        }
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _screens[currentIndex],
          bottomNavigationBar: StylishBottomBar(
            backgroundColor: Colors.transparent,
            currentIndex: currentIndex,
            onTap: ontap,
            items: [
              BottomBarItem(icon: Icon(FeatherIcons.home), title: Text("Home")),
              BottomBarItem(
                icon: Icon(FeatherIcons.inbox),
                title: Text("Inbox"),
              ),
              BottomBarItem(
                icon: Icon(FeatherIcons.user),
                title: Text("Profile"),
              ),
              // BottomBarItem(icon: Icon(FeatherIcons.video), title: Text("Clips")),
            ],
            option: DotBarOptions(dotStyle: DotStyle.tile),
          ),
        );
      },
    );
  }
}
