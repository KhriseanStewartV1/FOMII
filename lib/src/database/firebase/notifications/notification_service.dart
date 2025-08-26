// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static const String _baseUrl =
      "https://us-central1-fomo-connect.cloudfunctions.net";
  FirebaseMessaging fcm = FirebaseMessaging.instance;
  final db = FirebaseFirestore.instance;

  Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await Permission.notification.request();
      return false;
    } else {
      return false;
    }
  }

  //get token
  Future<void> saveToken(String uid, String token) async {
    String? platform;
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    } else {
      platform = null; // Or handle other platforms as needed
    }

    if (platform != null) {
      try {
        await db.collection('users').doc(uid).set({
          'token': token,
          'platform': platform,
        }, SetOptions(merge: true));
        print("Token saved for user $uid");
      } catch (e) {
        print("Error saving token: $e");
      }
    } else {
      print("Unsupported platform.");
    }
  }

  Future<String?> getToken(String uid) async {
    final doc = await db.collection("users").doc(uid).get();
    if (doc.exists) {
      return doc.data()?['token'] as String?;
    } else {
      return null;
    }
  }

  void pushToken(String uid) async {
    String? token = await fcm.getToken();
    if (token == null) {
      print("FCM token is null");
      return;
    }

    try {
      final doc = await db.collection('users').doc(uid).get();
      final savedToken = doc.data()?['token'] as String?;

      if (savedToken != token) {
        // Only save if token changed or not set
        await saveToken(uid, token);
        print("Token saved/updated for user $uid");
      } else {
        print("Token unchanged, no need to save");
      }
    } catch (e) {
      print("Error checking/saving token: $e");
    }
  }

  void setupForegroundMessaging(
    BuildContext context,
    VoidCallback showNotificationDialog,
  ) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Instead of directly showing dialog, invoke the callback
      showNotificationDialog();
    });
  }

  //forground messaging
  void firebaseMessaging(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "N/A";
      final body = message.notification?.body ?? "N/A";
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(
            body,
            maxLines: 1,
            style: TextStyle(overflow: TextOverflow.ellipsis),
          ),
          actions: [
            TextButton(
              onPressed: () {
                //Push to notification screen
              },
              child: Text("Next"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        ),
      );
    });
  }

  void backgroundNotification(BuildContext context, titletext, bodytext) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? titletext;
      final body = message.notification?.body ?? bodytext;
      Navigator.pushNamed(context, AppRouter.notifications);
      print("something here");
    });
  }

  void terminatedApp(BuildContext context) {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final title = message.notification?.title ?? "N/A";
        final body = message.notification?.body ?? "N/A";
        Navigator.pushNamed(context, AppRouter.notifications);
        print("here too");
      } else {
        print("error");
      }
    });
  }

  static Future<bool> sendPushNotificationv2({
    required String deviceToken,
    required String title,
    required String body,
  }) async {
    final url = Uri.parse("$_baseUrl/sendPushNotification");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"title": title, "body": body, "token": deviceToken}),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent: ${response.body}");
        return true;
      } else {
        print("⚠️ Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error sending push notification: $e");
      return false;
    }
  }

  static Future<bool> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
  }) async {
    final url = Uri.parse("$_baseUrl/sendTopicNotification");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"title": title, "body": body, "topic": topic}),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent: ${response.body}");
        return true;
      } else {
        print("⚠️ Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error sending push notification: $e");
      return false;
    }
  }
}
