import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void displaySnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = Colors.lightBlueAccent,
  Color textColor = Colors.black,
  Duration duration = const Duration(seconds: 5),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        child: Text(message, style: TextStyle(color: textColor)),
      ),
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}

void displayRoundedSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = Colors.lightBlueAccent,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
}) {
  final snackBar = SnackBar(
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    duration: duration,
    content: Center(
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(message, style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold)),
        ),
      ),
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void displayFloatingSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = Colors.lightBlueAccent,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
}) {
  final snackBar = SnackBar(
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
    backgroundColor: Colors.transparent,
    behavior: SnackBarBehavior.floating,
    duration: duration,
    margin: EdgeInsets.only(
      top: 20,
      left: 20,
      right: 20,
    ),

    content: Center(
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(message, style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold)),
        ),
      ),
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Color hexToColor(String hexCode) {
  final buffer = StringBuffer();
  if (hexCode.startsWith('#')) hexCode = hexCode.substring(1);
  if (hexCode.length == 6) buffer.write('ff');
  buffer.write(hexCode.toUpperCase());
  return Color(int.parse(buffer.toString(), radix: 16));
}
