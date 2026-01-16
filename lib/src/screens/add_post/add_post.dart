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
import 'package:fomo_connect/src/modal/event_model.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/widgets/event_widget/event_post_card.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:fomo_connect/src/widgets/quill_mentioner.dart';
import 'package:fomo_connect/src/widgets/video_player_screen/video_player_screen.dart';
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
  DateTime? selectedDate;

  late final ScrollController _scrollController;
  late final FocusNode _focusNode;

  List<Map<String, dynamic>> mediaFiles = [];
  File? postFile;
  bool _isLoading = false;

  bool anonymous = AuthService().user!.isAnonymous;
  List<String> tags = [];
  List<String> mentionedUsers = [];

  double progress = 0;
  bool loadingVideo = false;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  EventModel? event;

  String postIn = "Everyone";

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    tagController.dispose();
  }

  Future<void> pickImage({bool fromCamera = false}) async {
    final dir = await Directory.systemTemp.createTemp();
    if (mediaFiles.length >= 3) return;
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
          if (mediaFiles.length < 3) {
            mediaFiles.add({"file": finalFile, "type": "image"});
          }
        });

        // Upload and insert image into Quill doc
        await ImageService().uploadImage(file: finalFile, uid: user!.uid);
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n');
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Future<void> pickVideo() async {
    setState(() {
      loadingVideo = true;
    });
    if (mediaFiles.length >= 3) return;
    try {
      final video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(minutes: 3),
      );
      if (video != null) {
        final fileVid = toFile(video);
        final compressVid = await compressVideo(
          fileVid,
          'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
        );

        setState(() {
          if (mediaFiles.length < 3) {
            mediaFiles.add({"file": compressVid, "type": "video"});
          }
        });

        // Upload and insert image into Quill doc
        await ImageService().uploadVideoWithProgress(
          file: compressVid!,
          uid: user!.uid,
        );
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n');
      }
    } catch (e) {
      debugPrint("Video pick error: $e");
    } finally {
      setState(() {
        loadingVideo = false;
      });
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

  Future<void> mentionedUser() async {
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
          receiverUid: mentionedUniqueId,
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
          receiverUid: people,
        );
      }
    }
  }

  Future<void> handleSubmit() async {
    setState(() => _isLoading = true);
    final postContent = _controller.document.toDelta().toJson();

    try {
      Map<String, dynamic> mediaUrls = {};
      int counter = 0;
      double totalBytes = 0;
      double uploadedBytes = 0;

      // calculate total bytes of all media files
      for (var media in mediaFiles) {
        totalBytes += await media["file"].length();
      }

      for (var media in mediaFiles) {
        final file = media["file"] as File;
        final type = media["type"] as String;

        String? url;

        if (type == "image") {
          url = await ImageService().uploadImage(
            file: file,
            uid: user!.uid,
            onProgress: (d) {
              setState(() {
                uploadedBytes += d;
                progress = uploadedBytes / totalBytes;
                print(progress);
              });
            },
          );
        } else if (type == "video") {
          url = await ImageService().uploadVideoWithProgress(
            file: file,
            uid: user!.uid,
            onProgress: (d) {
              setState(() {
                uploadedBytes += d * file.lengthSync();
                progress = uploadedBytes / totalBytes;
              });
            },
          );
        }

        if (url != null) {
          mediaUrls["media_$counter"] = {"url": url, "type": type};
          counter++;
        }
      }

      PostModal post = PostModal(
        uuid: uuid,
        postIn: postIn,
        userId: anonymous ? "anonymous" : user!.uid,
        userName: anonymous ? "anonymous" : userName!,
        richText: postContent,
        tags: tags,
        timestamp: DateTime.now(),
        media: [mediaUrls],
        event: anonymous ? null : event,
      );

      await PostServices().post(post, uuid);

      await HapticFeedback.heavyImpact();
      await mentionedUser();
      await followersNoti();
      displayRoundedSnackBar(context, "Posted");
      Navigator.pop(context);
    } catch (e) {
      displaySnackBar(context, "Error: $e");
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          progress = 0.0;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? eventDate = selectedDate ?? DateTime.now();
    Future<void> showEventDialog() async {
      await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Create Event",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Location
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: "Location",
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // City
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: "City",
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date picker
                    Row(
                      children: [
                        const Text("Date: "),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: eventDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2099),
                            );
                            if (picked != null) {
                              setState(() {
                                eventDate = picked;
                              });
                            }
                          },
                          child: Text(
                            "${eventDate?.day}/${eventDate?.month}/${eventDate?.year}",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (titleController.text.isEmpty ||
                                locationController.text.isEmpty ||
                                cityController.text.isEmpty) {
                              displaySnackBar(
                                context,
                                "All fields are required",
                              );
                              return;
                            }

                            setState(() {
                              selectedDate = eventDate;
                            });

                            // Create EventModel
                            setState(() {
                              event = EventModel(
                                title: titleController.text.trim(),
                                dateTime: eventDate!.toIso8601String(),
                                location: locationController.text.trim(),
                                city: cityController.text.trim(),
                              );
                            });

                            Navigator.pop(context);

                            // You can now assign this event to your PostModal
                            print("Event Created: ${event?.title}");
                          },
                          child: const Text("Create"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 10),
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          GestureDetector(
            onTap: _isLoading ? null : handleSubmit,
            child: Text(
              _isLoading ? "Posting..." : 'Post',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Column(
                children: [
                  if (_isLoading && progress > 0)
                    LinearProgressIndicator(
                      value: progress,
                      color: Colors.grey,
                      valueColor: AlwaysStoppedAnimation(
                        Colors.lightBlueAccent,
                      ),
                    ),
                  _buildProfile(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: MentionQuillEditor(
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        controller: _controller,
                        onMentionSelected: (mentionId) {
                          // Here mentionId is the actual user uid
                          if (!mentionedUsers.contains(mentionId)) {
                            mentionedUsers.add(mentionId);
                          }
                          print('Mentioned Users IDs: $mentionedUsers');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (mediaFiles.length > 0)
                    Container(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: mediaFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = mediaFiles[index];
                          final file = item["file"] as File;
                          final type = item["type"];

                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: type == "image"
                                    ? Image.file(
                                        file,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : type == "video"
                                    ? GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => VideoPlayerScreen(
                                                file: file,
                                                isUrl: false,
                                              ),
                                            ),
                                          );
                                        },
                                        child: FutureBuilder<Uint8List?>(
                                          future: getVideoThumbnail(file.path),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                width: 120,
                                                height: 120,
                                                color: Colors.black12,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            if (!snapshot.hasData) {
                                              return Container(
                                                width: 120,
                                                height: 120,
                                                color: Colors.black12,
                                                child: const Icon(
                                                  Icons.videocam,
                                                  color: Colors.blue,
                                                ),
                                              );
                                            }
                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Image.memory(
                                                  snapshot.data!,
                                                  width: 120,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                ),
                                                const Icon(
                                                  Icons.play_circle_fill,
                                                  size: 40,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => mediaFiles.removeAt(index));
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black54,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (selectedDate != null) EventPostCard(event: event!),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.14, // default height (70%)
              minChildSize: 0.14, // collapsed height
              maxChildSize: 0.95, // fully expanded
              snapSizes: [0.14, 0.95],
              snap: true,
              shouldCloseOnMinExtent: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 2.0,
                    ),
                    child: Column(
                      spacing: 8,
                      children: [
                        SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(color: Colors.grey),
                            height: 4.0,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  onDeleted: () =>
                                      setState(() => tags.remove(tag)),
                                ),
                              )
                              .toList(),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.videocam_rounded,
                            color: Colors.red,
                            size: 28,
                          ),
                          title: Text(
                            "Upload Video",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () => loadingVideo ? null : pickVideo(),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.image_rounded,
                            color: Colors.lightBlueAccent,
                            size: 28,
                          ),
                          title: Text(
                            "From Gallery",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () => pickImage(fromCamera: false),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.camera,
                            color: Colors.orange,
                            size: 28,
                          ),
                          title: Text(
                            "Take Picture",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            pickImage(fromCamera: true);
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_month,
                            color: event == null ? Colors.green : Colors.grey,
                            size: 28,
                          ),
                          title: Text(
                            "Set Date",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () async {
                            event == null ? showEventDialog() : null;
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.tag,
                            color: Colors.amberAccent,
                            size: 28,
                          ),
                          title: Text(
                            "Tag",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Tag",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: tagController,
                                              decoration: const InputDecoration(
                                                hintText: 'Add a tag',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                              ),
                                              onSubmitted: (_) => addTag(),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: addTag,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // ListTile(
                        //   leading: Icon(
                        //     Icons.group_add_outlined,
                        //     color: Colors.amberAccent,
                        //     size: 28,
                        //   ),
                        //   title: Text(
                        //     "Mention Someone",
                        //     style: GoogleFonts.poppins(
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.w400,
                        //     ),
                        //   ),
                        //   onTap: () => showDialog(
                        //     context: context,
                        //     builder: (context) {
                        //       return Dialog(
                        //         child: Padding(
                        //           padding: const EdgeInsets.all(18.0),
                        //           child: Column(
                        //             mainAxisSize: MainAxisSize.min,
                        //             crossAxisAlignment:
                        //                 CrossAxisAlignment.center,
                        //             children: [
                        //               Text(
                        //                 "Tag",
                        //                 style: GoogleFonts.poppins(
                        //                   fontSize: 18,
                        //                   fontWeight: FontWeight.bold,
                        //                 ),
                        //               ),
                        //               SizedBox(height: 20),
                        //               Row(
                        //                 children: [
                        //                   Expanded(
                        //                     child: MentionTextField(
                        //                       controller: _mentionController,
                        //                       onMentionSelected: (mentionId) {
                        //                         mentionedUsers.add(mentionId);
                        //                       },
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
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
      future: UserServices().readUser(AuthService().user!.uid),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
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
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            Spacer(),
            // SizedBox(
            //   height: 40,
            //   child: DropdownButton<String>(
            //     value: postIn,
            //     underline: const SizedBox(),
            //     items: const [
            //       DropdownMenuItem(value: "Everyone", child: Text("Everyone")),
            //       DropdownMenuItem(
            //         value: "Following",
            //         child: Text("Following"),
            //       ),
            //       DropdownMenuItem(value: "Circles", child: Text("Circles")),
            //     ],
            //     onChanged: (value) {
            //       setState(() {
            //         postIn = value!;
            //       });
            //     },
            //   ),
            // ),
          ],
        );
      },
    );
  }
}
