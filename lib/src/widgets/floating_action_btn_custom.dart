import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/screens/circle_screen/circle_screen.dart';

class ExpandableFab extends StatefulWidget {
  @override
  _ExpandableFabState createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> {
  bool _showExtra = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // if (_showExtra)
        //   Padding(
        //     padding: const EdgeInsets.only(bottom: 120), // position above
        //     child: FloatingActionButton(
        //       mini: true,
        //       heroTag: 'Create Circle',
        //       tooltip: 'Create Post',
        //       onPressed: () {
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(builder: (_) => CirclesScreen()),
        //         );
        //       },
        //       child: Icon(Icons.circle_outlined),
        //     ),
        //   ),
        if (_showExtra)
          Padding(
            padding: const EdgeInsets.only(bottom: 70), // position above
            child: FloatingActionButton(
              mini: true,
              heroTag: 'Add Post',
              tooltip: 'Create Post',
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.addPost);
              },
              child: Icon(Icons.edit),
            ),
          ),
        FloatingActionButton(
          heroTag: 'main',
          backgroundColor: Theme.of(context).colorScheme.secondary,
          shape: CircleBorder(),
          onPressed: () {
            setState(() {
              _showExtra = !_showExtra;
            });
          },
          tooltip: 'Create a Post',
          child: Icon(_showExtra ? Icons.close : Icons.edit),
        ),
      ],
    );
  }
}
