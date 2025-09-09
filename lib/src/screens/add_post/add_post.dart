import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/others/image.dart';
import 'package:fomo_connect/src/database/storage/image.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
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
  final quill.QuillController _controller = quill.QuillController.basic();
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

        // Insert into Quill editor
        final url = await ImageService().uploadImage(file: postFile!, uid: user!.uid);
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n');
        _controller.document.insert(index + 1, quill.BlockEmbed.image(url!));
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

        final url = await ImageService().uploadImage(file: postFile!, uid: user!.uid);
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n');
        _controller.document.insert(index + 1, quill.BlockEmbed.image(url!));
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
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where('uniqueId', isEqualTo: mentionedUniqueId)
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) continue;

      final userDoc = querySnap.docs.first;
      // ignore: unused_local_variable
      final receiverUid = userDoc.id;
      final deviceToken = userDoc['token'] as String?;
      if (deviceToken != null) {
        await NotificationService.sendPushNotificationv2(
          deviceToken: deviceToken,
          title: "$userName mentioned you!",
          body: _controller.document.toPlainText(),
          context: context
        );
      }
    }
  }

  followersNoti() async {
    final followers = await UserServices().getFollowing(uid);
    for (var people in followers) {
      final querySnap = await NotificationService()
      .getToken(people);

      if (querySnap != null) {
        await NotificationService.sendPushNotificationv2(
          deviceToken: querySnap,
          title: "$userName Posted",
          body: _controller.document.toPlainText(),
          context: context
        );
      }
    }
  }

    void handleSubmit() async {
    setState(() {
      _isLoading = true;
    });
    // Handle post submission
    final postContent = _controller.document.toDelta().toJson(); // Rich text JSON
    // Use 'tags' list as part of the post data
    print('Tags: $tags');
    try {
      if (file != null) {
        final url = await ImageService().uploadImage(
          file: postFile!,
          uid: user!.uid,
        );
      PostModal post = PostModal(
          uuid: uuid,
          userId: anonymous ? "anonymous" : user!.uid,
          userName: anonymous ? "anonymous" : userName!,
          richText: postContent,
          tags: tags,
          timestamp: DateTime.now(),
          imageUrl: url,
        );

        await PostServices().post(post, uuid);
      } else {
      PostModal post = PostModal(
        uuid: uuid,
        userId: anonymous ? "anonymous" : user!.uid,
        userName: anonymous ? "anonymous" : userName!,
        richText: postContent,
        tags: tags,
        timestamp: DateTime.now(),
      );

      await PostServices().post(post, uuid);

      }
      HapticFeedback.lightImpact();
      await checkUser(); // Check and send notifications to mentioned users
      await followersNoti();
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
        title: Text('Create Post', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          MaterialButton(
            onPressed: _isLoading ? null : handleSubmit,
            color: _isLoading ? Colors.grey : Theme.of(context).colorScheme.primary,
            child: Text(
              'Post',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              _buildProfile(),
              SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: quill.QuillEditor(
                    controller: _controller,
                    scrollController: ScrollController(),
                    focusNode: FocusNode(),
                    config: quill.QuillEditorConfig(
                      autoFocus: false,
                      expands: true,
                      padding: EdgeInsets.zero,
                      
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              if (file != null)
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      height: 200, // or any size you want
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(8),
                        child: Image.file(File(file!.path), fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 4),
              quill.QuillSimpleToolbar(controller: _controller, 
                config: quill.QuillSimpleToolbarConfig(
                  multiRowsDisplay: false, 
                  showAlignmentButtons: false, 
                  showClipboardCut: false,
                  showClipboardCopy: false,
                  showClipboardPaste: false,
                  showClearFormat: false,
                  showListCheck: false,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagController,
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
              Wrap(
                spacing: 8,
                children: tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => tags.remove(tag)),
                        ))
                    .toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: Icon(Icons.photo, color: Colors.green), onPressed: pickImage),
                  IconButton(icon: Icon(Icons.camera, color: Colors.red), onPressed: takePicture),
                  IconButton(
                    icon: Icon(Icons.videocam, color: Colors.lightBlueAccent),
                    onPressed: () {followersNoti();},
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
            if (s.connectionState == ConnectionState.waiting) return LoadingScreen();
            if (!s.hasData || s.data == null || anonymous) {
              return CircleAvatar(radius: 25, child: Icon(Icons.person, size: 27));
            }
            final data = s.data;
            return ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: data?['profilePic'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
        SizedBox(width: 10),
        Text(userName ?? "Anonymous", style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 18)),
      ],
    );
  }
}
