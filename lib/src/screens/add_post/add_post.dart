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
  final TextEditingController tagController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final userName = FirebaseAuth.instance.currentUser!.displayName;
  final String uuid = const Uuid().v4();

  late final ScrollController _scrollController;
  late final FocusNode _focusNode;

  XFile? file;
  File? postFile;
  bool _isLoading = false;

  bool anonymous = AuthService().user!.isAnonymous;
  List<String> tags = [];
  List<String> mentionedUsers = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();

  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    tagController.dispose();
    super.dispose();
  }


  Future<void> pickImage({bool fromCamera = false}) async {
    final dir = await Directory.systemTemp.createTemp();
    try {
      final image = await ImagePicker().pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      if (image != null) {
        final fileImg = toFile(image);
        final compressImg = await compressImage(
          fileImg,
          800,
          800,
          75,
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        final finalFile = await toFile(compressImg!);
        setState(() {
          file = compressImg;
          postFile = finalFile;
        });

        // Upload and insert image into Quill doc
        await ImageService().uploadImage(file: postFile!, uid: user!.uid);
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n');
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
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

  Future<void> checkUser() async {
    for (var mentionedUniqueId in mentionedUsers) {
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where('uniqueId', isEqualTo: mentionedUniqueId)
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) continue;

      final userDoc = querySnap.docs.first;
      final deviceToken = userDoc['token'] as String?;
      if (deviceToken != null) {
        await NotificationService.sendPushNotificationv2(
          deviceToken: deviceToken,
          title: "$userName mentioned you!",
          body: _controller.document.toPlainText(),
          context: context,
        );
      }
    }
  }

  Future<void> followersNoti() async {
    final followers = await UserServices().getFollowing(user!.uid);
    for (var people in followers) {
      final querySnap = await NotificationService().getToken(people);

      if (querySnap != null) {
        await NotificationService.sendPushNotificationv2(
          deviceToken: querySnap,
          title: "$userName Posted",
          body: _controller.document.toPlainText(),
          context: context,
        );
      }
    }
  }

  Future<void> handleSubmit() async {
    setState(() => _isLoading = true);

    final postContent = _controller.document.toDelta().toJson();

    try {
      String? url;
      if (file != null) {
        url = await ImageService().uploadImage(file: postFile!, uid: user!.uid);
      }

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

      HapticFeedback.lightImpact();
      await checkUser();
      await followersNoti();
      displayRoundedSnackBar(context, "Posted");
      Navigator.pop(context);
    } catch (e) {
      displaySnackBar(context, "Error : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          MaterialButton(
            onPressed: _isLoading ? null : handleSubmit,
            color: _isLoading ? Colors.grey : Theme.of(context).colorScheme.primary,
            child: _isLoading ? LoadingScreen() : Text('Post', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              _buildProfile(),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: quill.QuillEditor(
                    controller: _controller,
                    scrollController: _scrollController,
                    focusNode: _focusNode,
                    config: const quill.QuillEditorConfig(
                      autoFocus: false,
                      expands: true,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (file != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(file!.path), fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 4),
              quill.QuillSimpleToolbar(
                controller: _controller,
                config: const quill.QuillSimpleToolbarConfig(
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
                      decoration: const InputDecoration(
                        hintText: 'Add a tag',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: (_) => addTag(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add), onPressed: addTag),
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
                  IconButton(
                      icon: const Icon(Icons.photo, color: Colors.green),
                      onPressed: () => pickImage(fromCamera: false)),
                  IconButton(
                      icon: const Icon(Icons.camera, color: Colors.red),
                      onPressed: () => pickImage(fromCamera: true)),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.lightBlueAccent),
                    onPressed: followersNoti,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile() {
    if (anonymous) {
      return const Row(
        children: [
          CircleAvatar(radius: 25, child: Icon(Icons.person, size: 27)),
          SizedBox(width: 10),
          Text("Anonymous", style: TextStyle(fontSize: 18)),
        ],
      );
    }

    return FutureBuilder(
      future: UserServices().readUser(uid),
      builder: (context, snap) {
        if(!snap.hasData || snap.data == null){
          return const Row(
                  children: [
                    CircleAvatar(radius: 25, child: Icon(Icons.person, size: 27)),
                    SizedBox(width: 10),
                    Text("Anonymous", style: TextStyle(fontSize: 18)),
                  ],
                );
        }
        final _userData = snap.data;
        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: _userData?['profilePic'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              userName ?? "Anonymous",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 18),
            ),
          ],
        );
      }
    );
  }
}
