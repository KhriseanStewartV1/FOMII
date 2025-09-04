import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/others/image.dart';
import 'package:fomo_connect/src/database/storage/image.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/mention_text_field.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  TextEditingController postController = TextEditingController();
  TextEditingController tagController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final userName = FirebaseAuth.instance.currentUser!.displayName;
  List<String> tags = [];
  String uuid = Uuid().v4();

  XFile? file;
  File? postFile;
  bool _isLoading = false;

  bool anonymous = AuthService().user!.isAnonymous;

  List<String> mentionedUsers = [];

  void pickImage() async {
    final dir = await Directory.systemTemp.createTemp();
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final fileImg = toFile(image);
        final compressImg = await compressImage(
          fileImg,
          800,
          800,
          75,
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        setState(() {
          file = compressImg;
        });
        final finalFile = await toFile(compressImg!);
        setState(() {
          postFile = finalFile;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void takePicture() async {
    final dir = await Directory.systemTemp.createTemp();
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        final fileImg = toFile(image);
        final compressImg = await compressImage(
          fileImg,
          800,
          800,
          75,
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        setState(() {
          file = compressImg;
        });
        final finalFile = await toFile(compressImg!);
        setState(() {
          postFile = finalFile;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void addTag() {
    String newTag = tagController.text.trim();
    if (newTag.isNotEmpty && !tags.contains(newTag)) {
      setState(() {
        tags.add(newTag);
      });
      tagController.clear();
    }
  }

  checkUser() async {
    for (var mentionedUniqueId in mentionedUsers) {
      // Query the 'users' collection to get the real uid
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where('uniqueId', isEqualTo: mentionedUniqueId)
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) {
        print("No user found for $mentionedUniqueId");
        continue; // skip if user doesn't exist
      }

      final userDoc = querySnap.docs.first;
      final receiverUid = userDoc.id; // Firestore document ID
      final deviceToken = userDoc['token'] as String?;
      await NotificationService.sendPushNotificationv2(
        deviceToken: deviceToken!,
        title: "$userName messaged you!",
        body: postController.text,
      );
      print("Notification sent to $mentionedUniqueId -> $receiverUid");
    }
  }

  void handleSubmit() async {
    setState(() {
      _isLoading = true;
    });
    // Handle post submission
    String postText = postController.text.toLowerCase();
    // Use 'tags' list as part of the post data
    print('Post: $postText');
    print('Tags: $tags');
    try {
      if (file != null) {
        final url = await ImageService().uploadImage(
          file: postFile!,
          uid: user!.uid,
        );
        await PostServices().post(
          PostModal(
            uuid: uuid,
            userId: user!.uid,
            userName: userName!,
            postText: postText,
            imageUrl: url,
            tags: tags,
            timestamp: DateTime.now(),
          ),
          uuid,
        );
      } else {
        await PostServices().post(
          PostModal(
            uuid: uuid,
            userId: user!.uid,
            userName: userName!,
            postText: postText,
            tags: tags,
            timestamp: DateTime.now(),
          ),
          uuid,
        );
      }
      HapticFeedback.lightImpact();
      await checkUser(); // Check and send notifications to mentioned users
      displayRoundedSnackBar(context, "Posted");
      Navigator.pop(context); // Close after posting
    } catch (e) {
      displaySnackBar(context, "Error : $e");
    } finally {
      setState(() {
        _isLoading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        actions: [
          MaterialButton(
            onPressed: _isLoading ? null : handleSubmit,
            color: _isLoading
                ? Colors.transparent
                : Theme.of(context).colorScheme.primary,
            child: Text(
              'Post',
              style: GoogleFonts.poppins(
                color: _isLoading ? Colors.transparent : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info row
              _buildProfile(),
              SizedBox(height: 10),
              // Post input
              Expanded(
                child: MentionTextField(
                  controller: postController,
                  onMentionSelected: (mentionId) {
                    // Here mentionId is the actual user uid
                    if (!mentionedUsers.contains(mentionId)) {
                      mentionedUsers.add(mentionId);
                    }
                    print('Mentioned Users IDs: $mentionedUsers');
                  },
                ),
              ),
              SizedBox(height: 4),
              if (file != null)
                Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  height: 200, // or any size you want
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(8),
                    child: Image.file(File(file!.path), fit: BoxFit.cover),
                  ),
                ),
              SizedBox(height: 4),
              // Tag input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagController,
                      keyboardType: TextInputType.twitter,
                      decoration: InputDecoration(
                        hintText: 'Add a tag',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: (_) => addTag(),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.add), onPressed: addTag),
                ],
              ),
              // Display tags as chips
              Wrap(
                spacing: 8,
                children: tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setState(() {
                            tags.remove(tag);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              // Optional media buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.photo, color: Colors.green),
                    onPressed: () {
                      pickImage();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.camera, color: Colors.red),
                    onPressed: () {
                      takePicture();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.videocam, color: Colors.lightBlueAccent),
                    onPressed: () {
                      displayRoundedSnackBar(
                        context,
                        "Video Upload is currently Unavailable",
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildProfile() {
    return Row(
      children: [
        FutureBuilder(
          future: UserServices().readUser(user!.uid),
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return Center(child: LoadingScreen());
            }
            if (!s.hasData || s.data == null || anonymous) {
              return CircleAvatar(
                radius: 25,
                child: Icon(Icons.person, color: Colors.black, size: 27),
              );
            }
            final data = s.data;
            return ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(25),
              child: CachedNetworkImage(
                imageUrl: data?['profilePic'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, progress) {
                  return CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(
                      data?['profilePic'],
                    ), // Placeholder
                  );
                },
                errorWidget: (context, url, error) {
                  return CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.black, size: 27),
                  );
                },
              ),
            );
          },
        ),
        SizedBox(width: 10),
        Text(
          userName ?? "Anonymous",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
