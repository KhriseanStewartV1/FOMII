import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

// Inside your HomeScreen build method
// ignore: must_be_immutable
class IconBadge extends StatelessWidget {
  Icon icon;
  VoidCallback onpress;
  String? tooltip;
  Stream stream;
  IconBadge({
    super.key,
    required this.icon,
    required this.onpress,
    this.tooltip,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          // Only count unread notifications
          count = snapshot.data!.where((n) => !n.isRead).length;
        }

        return badges.Badge(
          showBadge: count > 0,
          badgeContent: Text(
            count.toString(),
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          child: IconButton(
            tooltip: tooltip,
            icon: icon,
            onPressed: onpress,
            style: IconButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
