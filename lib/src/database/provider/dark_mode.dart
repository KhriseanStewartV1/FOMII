import 'package:flutter/material.dart';
import 'package:fomo_connect/theme.dart';

//requires provider

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;
  bool _isDarkMode = false;

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    themeData = value ? darkMode : lightMode;
    print("$value _ $themeData _$isDarkMode");
  }
}
