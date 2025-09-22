import 'package:flutter/material.dart';

class CalenderDateWidget extends StatelessWidget {
  const CalenderDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker(
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2099),
      onDateChanged: (value) {},
    );
  }
}
