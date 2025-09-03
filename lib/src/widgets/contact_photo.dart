import 'dart:typed_data';
import 'package:flutter/material.dart';

class ContactPhotoWidget extends StatelessWidget {
  final Uint8List? photoData;

  const ContactPhotoWidget({Key? key, this.photoData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photoData == null) {
      // Show a placeholder or default avatar if no photo
      return CircleAvatar(
        radius: 40,
        child: Icon(Icons.person),
      );
    } else {
      // Display the photo
      return CircleAvatar(
        radius: 40,
        backgroundImage: MemoryImage(photoData!),
      );
    }
  }
}