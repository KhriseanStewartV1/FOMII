import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/provider/post_provider.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/screens/profile_screen/user_profile.dart';
import 'package:fomo_connect/src/widgets/constants.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

// ignore: must_be_immutable
class PostWidget extends StatefulWidget {
  PostModal post;
  PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

String uid = FirebaseAuth.instance.currentUser!.uid;
final _commentController = TextEditingController();
final Map<String, DocumentSnapshot> _profileCache = {};

Future<ui.Image> _getImageSize(String url) async {
  final completer = Completer<ui.Image>();
  final image = NetworkImage(url);
  image
      .resolve(const ImageConfiguration())
      .addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
        }),
      );
  return completer.future;
}

Future<DocumentSnapshot?> _getProfile(String userId) async {
  if (_profileCache.containsKey(userId)) {
    return _profileCache[userId];
  } else {
    final doc = await PostServices().getProfile(userId);
    if (doc != null) _profileCache[userId] = doc;
    return doc;
  }
}

class _PostWidgetState extends State<PostWidget> {
  bool isFollowing = false;
  void userComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    // Ensure you have access to the 'data' for user info
    // You can pass it as a parameter or manage it accordingly
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

    _commentController.clear(); // Clear input after sending
    setState(() {}); // Optional, refresh UI if needed
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostProfileText(widget.post),
          SizedBox(height: 8),
          if (widget.post.imageUrl != null) _buildImageRatio(widget.post),
          SizedBox(height: 8),
          Text(
            maxLines: 2,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
            widget.post.postText,
            style: GoogleFonts.poppins(fontSize: 15),
          ),
          if (size.width < 361)
            _buildSmallerBottomPostBar(widget.post)
          else
            _buildBottomPostBar(widget.post),
        ],
      ),
    );
  }

  Widget _buildImageRatio(PostModal post) {
    return FutureBuilder(
      future: _getImageSize(post.imageUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Image.network(post.imageUrl!, fit: BoxFit.contain);
        }
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        final imageInfo = snapshot.data!;
        final aspectRatio = imageInfo.width / imageInfo.height;

        return GestureDetector(
          onTap: () {
            _openFullScreenImage(context, post.imageUrl!);
          },
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: CachedNetworkImage(
              imageUrl: post.imageUrl!,
              fit: BoxFit.contain,
              memCacheHeight: imageInfo.height,
              memCacheWidth: imageInfo.width,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  Center(
                    child: CircularProgressIndicator(
                      value: downloadProgress.progress,
                    ),
                  ),
              errorWidget: (context, url, error) =>
                  Center(child: Icon(Icons.error)),
            ),
          ),
        );
      },
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
            tag:
                imageUrl, // optional: for smooth transition if using Hero elsewhere
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

  Widget _buildBottomPostBar(PostModal post) {
    final posts = Provider.of<PostProvider>(context).posts[post.uuid]!;
    final isLiked = posts.likes.contains(uid);
    final isReposted = posts.reposts.contains(uid);
    final likesCount = posts.likes.length;
    final repostsCount = posts.reposts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              backgroundColor: isLiked
                  ? hexToColor("#FF5252")
                  : Colors.transparent,
            ),
            onPressed: () {
              Provider.of<PostProvider>(
                context,
                listen: false,
              ).toggleLike(post.uuid, uid, context);
            },
            child: _buildBottomPostOptions(
              "${likesCount == 0 ? 'Like' : likesCount}",
              Icon(
                size: 24,
                FeatherIcons.thumbsUp,
                color: isLiked
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              showCommentModal();
            },
            child: _buildBottomPostOptions(
              "Comment",
              Icon(FeatherIcons.messageSquare, size: 24),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              backgroundColor: isReposted
                  ? Colors.lightBlueAccent.shade200
                  : Colors.transparent,
            ),
            onPressed: () {
              Provider.of<PostProvider>(
                context,
                listen: false,
              ).toggleRepost(post.uuid, uid, context);
            },
            child: _buildBottomPostOptions(
              "${repostsCount == 0 ? 'Repost' : repostsCount}",
              Icon(
                FeatherIcons.repeat,
                size: 24,
                color: isReposted
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallerBottomPostBar(PostModal post) {
    final posts = Provider.of<PostProvider>(context).posts[post.uuid]!;
    final isLiked = posts.likes.contains(uid);
    final isReposted = posts.reposts.contains(uid);
    final likesCount = posts.likes.length;
    final repostsCount = posts.reposts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              backgroundColor: isLiked
                  ? hexToColor("#FF5252")
                  : Colors.transparent,
            ),
            onPressed: () {
              Provider.of<PostProvider>(
                context,
                listen: false,
              ).toggleLike(post.uuid, uid, context);
            },
            child: _buildBottomPostOptions(
              "${likesCount == 0 ? '' : likesCount}",
              Icon(
                size: 24,
                FeatherIcons.thumbsUp,
                color: isLiked
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              showCommentModal();
            },
            child: _buildBottomPostOptions(
              "",
              Icon(FeatherIcons.messageSquare, size: 24),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              backgroundColor: isReposted
                  ? Colors.lightBlueAccent.shade200
                  : Colors.transparent,
            ),
            onPressed: () {
              Provider.of<PostProvider>(
                context,
                listen: false,
              ).toggleRepost(post.uuid, uid, context);
            },
            child: _buildBottomPostOptions(
              "${repostsCount == 0 ? '' : repostsCount}",
              Icon(
                FeatherIcons.repeat,
                size: 24,
                color: isReposted
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
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
                Divider(),
                SizedBox(height: 6),
                SizedBox(
                  height: SizeConfig.heightPercentage(40),
                  child: _buildCommentStream(),
                ),
                // Input area
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  comment, // Replace with actual message
                  style: GoogleFonts.poppins(
                    fontSize: 15,
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

  Widget _defaultPicCard(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Center(child: Icon(Icons.person, size: 30, color: Colors.white)),
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
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfile(user: data!)),
            );
          },
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 20,
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
                        spacing: 4,
                        children: [
                          Text(
                            data?['name'] ?? "Can't fetch User",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                    ],
                    onSelected: (value) async {
                      if (value == "follow") {
                        try {
                          print(post.userId);
                          String message = await UserServices().followingSystem(
                            post.userId,
                            isFollowing,
                          );
                          setState(() {
                            followMessage = message;
                            isFollowing = !isFollowing;
                          });
                          displayRoundedSnackBar(context, followMessage);
                        } catch (e) {
                          displayRoundedSnackBar(context, "An Error Happened");
                        }
                      }
                    },
                  ),
                ],
              ),
              // SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomPostOptions(String text, Icon icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4,
      children: [
        icon,
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
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
