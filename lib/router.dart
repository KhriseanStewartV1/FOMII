import 'package:flutter/material.dart';
import 'package:fomo_connect/src/main_layout/main_layout.dart';
import 'package:fomo_connect/src/screens/add_post/add_post.dart';
import 'package:fomo_connect/src/screens/auth/auth_wrapper/auth_wrapper.dart';
import 'package:fomo_connect/src/screens/auth/confirm_email/confirm_email_screen.dart';
import 'package:fomo_connect/src/screens/auth/forgot_password/forgot_password.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/screens/auth/sign_up_screen/sign_up_screen.dart';
import 'package:fomo_connect/src/screens/notifications/notification_screen.dart';
import 'package:fomo_connect/src/screens/settings_screen/setting_screen.dart';
import 'package:fomo_connect/src/widgets/splash_screen.dart';

class AppRouter {
  static const String login = "/";
  static const String splash = '/splash';

  static const String signup = "/signup";
  static const String confirmEmail = "/confirmEmail";
  static const String forgotPassword = "/forgotPassword";

  static const String authWrapper = "/authWrapper";

  static const String mainLayout = "/mainLayout";
  static const String settingScreen = "/settingScreen";

  static const String notifications = "/notifications";
  static const String addPost = "/addPost";

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),

      login: (context) => const LogInScreen(),
      signup: (context) => const SignUpScreen(),
      confirmEmail: (context) => const ConfirmEmailScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),

      authWrapper: (context) => const AuthWrapper(),

      mainLayout: (context) => const MainLayout(),
      settingScreen: (context) => const SettingScreen(),

      notifications: (context) => const NotificationScreen(),
      addPost: (context) => const AddPost(),
    };
  }

  // static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  //   final url = Uri.parse(settings.name ?? '');
  //   if (url.pathSegments.isNotEmpty && url.pathSegments.first == 'student') {
  //     final uid = url.pathSegments.length > 1 ? url.pathSegments[1] : '';
  //     return MaterialPageRoute(
  //       builder: (_) => MainLayout(uid: uid,),
  //     );
  //   }
  //   return null;
  // }
}
