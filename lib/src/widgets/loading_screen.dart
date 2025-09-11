import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LoadingScreen extends StatelessWidget {
  Color? color;
  double? value;
  LoadingScreen({super.key, this.color, this.value});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      backgroundColor: color,
      value: value,

    );
  }
}