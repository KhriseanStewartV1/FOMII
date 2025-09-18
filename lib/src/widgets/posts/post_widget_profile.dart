import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/widgets/constants.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/mention_text_field.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:fomo_connect/src/widgets/posts/carousel_slider_widget.dart';
import 'package:fomo_connect/src/widgets/posts/post_bottom_button_mq.dart';
import 'package:fomo_connect/src/widgets/posts/post_bottom_buttons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

// ignore: must_be_immutable
class PostWidgetProfile extends StatefulWidget {
  PostModal post;
  PostWidgetProfile({super.key, required this.post});

  @override
  State<PostWidgetProfile> createState() => _PostWidgetProfileState();
}

final Map<String, DocumentSnapshot> _profileCache = {};

Future<DocumentSnapshot?> _getProfile(String userId) async {
  if (_profileCache.containsKey(userId)) {
    return _profileCache[userId];
  } else {
    final doc = await PostServices().getProfile(userId);
    if (doc != null) _profileCache[userId] = doc;
    return doc;
  }
}

class _PostWidgetProfileState extends State<PostWidgetProfile> {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  bool isFollowing = false;
  final TextEditingController _commentController = TextEditingController();

  void userComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;
    final userData = await UserServices().readUser(uid);
    if (userData == null) return; // handle error if needed

    await PostServices().addComment(
      commentText,
      uid,
      userData['profilePic'],
      DateTime.now(),
      userData['name'],
      widget.post.uuid,
    );
    await NotificationService.sendPushNotificationv2(
      deviceToken: userData['token'],
      title: "${userData['name']} left a comment",
      body: commentText,
      context: context,
      receiverUid: widget.post.userId,
    );

    _commentController.clear(); // Clear input after sending
    setState(() {}); // Optional, refresh UI if needed
  }

  @override
  Widget build(BuildContext context) {
    final document = (widget.post.richText.isNotEmpty)
        ? quill.Document.fromJson(widget.post.richText)
        : quill.Document();
    final controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    final size = MediaQuery.of(context).size;
    controller.readOnly = true;
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostProfileText(widget.post),
          SizedBox(height: 8),
          if (widget.post.media.isNotEmpty) buildMedia(widget.post),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: quill.QuillEditor(
              controller: controller,
              scrollController: ScrollController(),
              focusNode: FocusNode(),
            ),
          ),
          SizedBox(height: 4),
          Divider(),
          if (size.width < 361)
            PostBottomButtons(post: widget.post)
          else
            PostBottomButtonMq(post: widget.post),
        ],
      ),
    );
  }

  String getFormattedDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(dateTime);
  }

  String getRelativeTime(DateTime dateTime) {
    return timeago.format(dateTime);
  }

  Widget _buildPostProfileText(PostModal post) {
    String followMessage = '';
    return FutureBuilder<DocumentSnapshot?>(
      future: _getProfile(post.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.grey[600]),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 12, color: Colors.grey[300]),
                  SizedBox(height: 4),
                  Container(width: 50, height: 10, color: Colors.grey[200]),
                ],
              ),
            ],
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(100),
                child: Icon(Icons.person, color: Colors.red),
              ),
            ),
          );
        }
        final data = snapshot.data;
        return FutureBuilder(
          future: UserServices().readUser(AuthService().user!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.grey[300]),
                      SizedBox(height: 4),
                      Container(width: 50, height: 10, color: Colors.grey[200]),
                    ],
                  ),
                ],
              );
            }
            final userInfo = userSnapshot.data!.data() as Map<String, dynamic>;
            print(userInfo);
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(100),
                            child: CachedNetworkImage(
                              imageUrl: data?['profilePic'] ?? '',
                              fit: BoxFit.cover,
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) => Center(
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person),
                                    ),
                                  ),
                              errorWidget: (context, url, error) {
                                return Center(child: Icon(Icons.person));
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  data?['name'] ?? "Can't fetch User",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                //     Text(
                                //       userInfo['uniqueId'] ?? "",
                                //       style: GoogleFonts.poppins(
                                //         fontSize: 12,
                                //         fontWeight: FontWeight.w400,
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                Text(
                                  getRelativeTime(post.timestamp),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        PopupMenuButton(
                          icon: Icon(Icons.more_horiz),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "follow",
                              child: Text(
                                followMessage == 'Already following'
                                    ? "Following"
                                    : 'Follow',
                              ),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == "follow") {
                              String message = await UserServices()
                                  .followingSystem(post.userId, isFollowing);
                              setState(() {
                                followMessage = message;
                                isFollowing = !isFollowing;
                              });
                              displayRoundedSnackBar(context, followMessage);
                            }
                            if (value == 'delete') {
                              bool isDeleting = await PostServices().deletePost(
                                post.uuid,
                              );

                              if (!mounted) return;

                              if (isDeleting) {
                                displayRoundedSnackBar(context, "Post Deleted");
                              } else {
                                displayRoundedSnackBar(
                                  context,
                                  "Error happened",
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    // SizedBox(height: 5),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _defaultPicCard(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Center(child: Icon(Icons.person, size: 30, color: Colors.white)),
    );
  }

  Widget _buildCommentStream() {
    return StreamBuilder(
      stream: PostServices().readComments(widget.post.uuid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LoadingScreen());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text("No Comments"));
        }
        final data = snapshot.data;
        if (data is List && data!.isEmpty) {
          return Center(child: Text("No Comments"));
        }
        return ListView.separated(
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemCount: data!.length, // Use actual data length
          itemBuilder: (context, index) {
            final commentData = data[index];
            final comment = commentData['comment'];
            final profilePic = commentData['profilePic'];
            final name = commentData['name'];
            final timestamp = commentData['timestamp'];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: profilePic == null || profilePic.isEmpty
                          ? _defaultPicCard(context)
                          : CachedNetworkImage(
                              imageUrl: profilePic,
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                              progressIndicatorBuilder:
                                  (context, child, progress) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                              errorWidget: (context, error, object) {
                                return _defaultPicCard(context);
                              },
                            ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  comment, // Replace with actual message
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(getFormattedDate(timestamp)),
                  ], // Replace as needed
                ),
              ],
            );
          },
        );
      },
    );
  }

  showCommentModal() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important to allow resize
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 15.0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Comments", style: Theme.of(context).textTheme.titleLarge),
                // Divider(),
                SizedBox(height: 6),
                SizedBox(
                  height: SizeConfig.heightPercentage(40),
                  child: _buildCommentStream(),
                ),
                // Input area
                Row(
                  children: [
                    Expanded(
                      child: MentionTextField(
                        controller: _commentController,
                        text: "Add a comment...",
                        onMentionSelected: (String mention) {
                          print("Mention selected: $mention");
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        userComment();
                      },
                      icon: Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildV1ProductCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //image
          AspectRatio(aspectRatio: 16 / 9, child: Placeholder()),
          //text
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Post Title',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Icon(FeatherIcons.thumbsUp),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Icon(FeatherIcons.repeat),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'Subtext or description goes here.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          //repost, like
        ],
      ),
    );
  }
}
