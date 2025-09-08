import 'dart:io';

import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/screens/forum/forum_screen.dart';
import 'package:fomo_connect/src/screens/home_screen/home_screen.dart';
import 'package:fomo_connect/src/screens/inbox_screen/inbox_screen.dart';
import 'package:fomo_connect/src/screens/profile_screen/profile_screen.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:upgrader/upgrader.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

List<Widget> _screens = [
  // CameraScreen(),
  HomeScreen(), 
  InboxScreen(), 
  ProfileScreen(),
  ForumScreen()
];

class _MainLayoutState extends State<MainLayout> {
  int currentIndex = 0;

  // ontap(int index) {
  //   if(index == 0){
  //     Navigator.push(context, MaterialPageRoute(builder: (context) => CameraScreen(),));
  //   }else {
  //   setState(() {
  //     currentIndex = index;
  //   });
  //   }
  // }

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
        return UpgradeAlert(
        barrierDismissible: false,
        showLater: true,
        showIgnore: false,
        dialogStyle: Platform.isIOS
            ? UpgradeDialogStyle.cupertino
            : UpgradeDialogStyle.material,
        upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(hours: 1),
          minAppVersion: "2.0.0",
        ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: _screens[currentIndex],
            bottomNavigationBar: StylishBottomBar(
              backgroundColor: Colors.transparent,
              currentIndex: currentIndex,
              onTap: ontap,
              items: [
                BottomBarItem(
                  icon: Icon(FeatherIcons.home), 
                  title: Text("Home"), 
                  selectedIcon: Icon(Icons.home_filled), 
                  selectedColor: Colors.lightBlue),
                BottomBarItem(
                  icon: Icon(FeatherIcons.inbox),
                  title: Text("Inbox"),
                  selectedIcon: Icon(Icons.inbox),
                  selectedColor: Colors.lightBlue
                ),
                BottomBarItem(
                  icon: Icon(FeatherIcons.user),
                  title: Text("Profile"),
                  selectedIcon: Icon(Icons.person),
                  selectedColor: Colors.lightBlue
                ),
              ],
              option: BubbleBarOptions(),
            ),
          ),
        );
      },
    );
  }
}
