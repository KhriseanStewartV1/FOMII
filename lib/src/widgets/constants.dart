import 'package:flutter/material.dart';

class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double? screenWidth;
  static double? screenHeight;
  static double? blockSizeHorizontal;
  static double? blockSizeVertical;

  // Initialize method to be called at the start of your widget build
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    blockSizeHorizontal = screenWidth! / 100;
    blockSizeVertical = screenHeight! / 100;
  }

  // Example constants based on screen size
  static double get appPadding => 16.0; // default padding
  static double get appMargin => 16.0; // default margin

  // You can add more constants or helper functions as needed
  static double widthPercentage(double percentage) {
    return screenWidth! * (percentage / 100);
  }

  static double heightPercentage(double percentage) {
    return screenHeight! * (percentage / 100);
  }
}
