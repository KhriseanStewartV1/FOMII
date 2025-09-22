import 'package:flutter/material.dart';

class BadgesWidget extends StatelessWidget {
  final double size;
  final bool verified;
  final bool betaTester;
  final bool tenPost;

  const BadgesWidget({
    super.key,
    this.size = 60,
    this.verified = false,
    this.betaTester = false,
    this.tenPost = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> badges = [];

    if (verified) {
      badges.add(
        Tooltip(
          message: "Verified User",
          child: Icon(Icons.verified, size: 18, color: Colors.blue),
        ),
      );
    }

    if (betaTester) {
      badges.add(
        Tooltip(
          message: "Beta Tester",
          child: Icon(Icons.bolt_rounded, size: 18, color: Colors.orange),
        ),
      );
    }

    if (tenPost) {
      badges.add(
        Tooltip(
          message: "10+ Posts",
          child: Icon(Icons.star, size: 18, color: Colors.amber),
        ),
      );
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink(); // nothing to show
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges
          .map(
            (badge) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: badge,
            ),
          )
          .toList(),
    );
  }
}
