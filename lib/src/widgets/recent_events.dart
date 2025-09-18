import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/status/status_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/others/image.dart';
import 'package:fomo_connect/src/database/storage/image.dart';
import 'package:fomo_connect/src/modal/status_model.dart';
import 'package:image_picker/image_picker.dart';

class RecentEvents extends StatefulWidget {
  const RecentEvents({super.key});

  @override
  State<RecentEvents> createState() => _RecentEventsState();
}

class _RecentEventsState extends State<RecentEvents> {
  Future<void> statusImg() async {
    try {
      final dir = await Directory.systemTemp.createTemp();
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final compressed = await compressImage(
        toFile(image),
        400,
        400,
        70,
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (compressed == null) return;

      final url = await ImageService().uploadStatus(
        file: toFile(compressed),
        uid: AuthService().user!.uid,
      );
      final userDoc = await UserServices().readUser(AuthService().user!.uid);
      print(userDoc!.data());
      await UserServices().updateUser({'status': url});
      await StatusService().uploadStatus(
        context,
        stat: StatusModel(
          url: url,
          userName: "userName",
          published: DateTime.now(),
        ),
        uid: AuthService().user!.uid,
      );
    } catch (e) {
      debugPrint("❌ Error picking/uploading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 90, maxHeight: 120),
      child: FutureBuilder(
        future: StatusService().readStatus(context),
        builder: (context, async) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemCount: 10,
            itemBuilder: (context, index) {
              if (index == 0) {
                // 👇 First circle = Add Event
                return GestureDetector(
                  onTap: statusImg,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade300,
                        child: const Icon(
                          Icons.add,
                          size: 32,
                          color: Colors.black,
                        ),
                      ),
                      Text("Add Event"),
                    ],
                  ),
                );
              }

              // 👇 Regular circles
              return GestureDetector(
                onTap: () => _openFullScreenImage(
                  context,
                  "https://th.bing.com/th/id/R.28a3e58f049ae2d5edd61d5e2c767643?rik=U%2fM8tTxy0BAlJg&pid=ImgRaw&r=0",
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        "https://th.bing.com/th/id/R.28a3e58f049ae2d5edd61d5e2c767643?rik=U%2fM8tTxy0BAlJg&pid=ImgRaw&r=0",
                      ),
                    ),
                    Text("Add Event"),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(), // tap to close
        child: Container(
          color: Colors.black.withOpacity(0.4),
          alignment: Alignment.center,
          child: Hero(
            tag: imageUrl,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
