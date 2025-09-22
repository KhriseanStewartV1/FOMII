import 'dart:io';

import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/firebase/chat/chat_service.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/screens/home_screen/home_screen.dart';
import 'package:fomo_connect/src/screens/inbox_screen/inbox_screen.dart';
import 'package:fomo_connect/src/screens/loading_splash.dart/splash_screen.dart';
import 'package:fomo_connect/src/screens/profile_screen/profile_screen.dart';
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
  // ForumScreen()
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
          return Center(child: LoadingSplashScreen(isStarting: false));
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
          upgrader: Upgrader(durationUntilAlertAgain: const Duration(hours: 1)),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: _screens[currentIndex],
            bottomNavigationBar: StreamBuilder(
              stream: ChatService().unreadMessagesCount(user.uid),
              builder: (context, snap) {
                if (!snap.hasData || snap.data == null) {
                  return StylishBottomBar(
                    backgroundColor: Colors.transparent,
                    currentIndex: currentIndex,
                    onTap: ontap,
                    items: [
                      BottomBarItem(
                        icon: Icon(FeatherIcons.home),
                        title: Text("Home"),
                        selectedIcon: Icon(Icons.home_filled),
                        selectedColor: Colors.lightBlue,
                      ),
                      BottomBarItem(
                        showBadge: false,
                        icon: Icon(FeatherIcons.inbox),
                        title: Text("Inbox"),
                        selectedIcon: Icon(Icons.inbox),
                        selectedColor: Colors.lightBlue,
                      ),
                      BottomBarItem(
                        icon: Icon(FeatherIcons.user),
                        title: Text("Profile"),
                        selectedIcon: Icon(Icons.person),
                        selectedColor: Colors.lightBlue,
                      ),
                    ],
                    option: BubbleBarOptions(),
                  );
                }
                final num = snap.data;
                return StylishBottomBar(
                  backgroundColor: Colors.transparent,
                  currentIndex: currentIndex,
                  onTap: ontap,
                  items: [
                    BottomBarItem(
                      icon: Icon(FeatherIcons.home),
                      title: Text("Home"),
                      selectedIcon: Icon(Icons.home_filled),
                      selectedColor: Colors.lightBlue,
                    ),
                    BottomBarItem(
                      showBadge: num! > 0 ? true : false,
                      badge: Text("$num"),
                      icon: Icon(FeatherIcons.inbox),
                      title: Text("Inbox"),
                      selectedIcon: Icon(Icons.inbox),
                      selectedColor: Colors.lightBlue,
                    ),
                    BottomBarItem(
                      icon: Icon(FeatherIcons.user),
                      title: Text("Profile"),
                      selectedIcon: Icon(Icons.person),
                      selectedColor: Colors.lightBlue,
                    ),
                  ],
                  option: BubbleBarOptions(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
