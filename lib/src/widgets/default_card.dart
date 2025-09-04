import 'package:flutter/material.dart';

class DefaultCard extends StatelessWidget {
  const DefaultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Center(child: Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.primary)),
    );
  }
}