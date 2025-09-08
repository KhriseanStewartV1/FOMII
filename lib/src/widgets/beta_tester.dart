import 'package:flutter/material.dart';

class BetaTesterBadge extends StatelessWidget {
  final double size;

  const BetaTesterBadge({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message:  "BETA TESTER",
            child: Icon(
              Icons.bolt_rounded,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
