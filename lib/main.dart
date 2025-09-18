import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/bootstrap/bootstrap.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/provider/dark_mode.dart';
import 'package:fomo_connect/src/database/provider/post_provider.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // your app icon

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await FlutterLocalNotificationsPlugin().initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Optional: navigate to your notifications screen
      // Navigator.pushNamed(context, AppRouter.notifications);
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BatchPostProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;

  if (notification != null) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'FOMII', // channel id
          'FOMII Notifications', // channel name
          importance: Importance.defaultImportance,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await FlutterLocalNotificationsPlugin().show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().terminatedApp(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FOMII',
      theme: Provider.of<ThemeProvider>(context).themeData,
      routes: AppRouter.routes,
      initialRoute: AppRouter.splash,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
      FlutterQuillLocalizations.delegate,

  ]
    );
  }
}
