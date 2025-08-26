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
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

// ignore: must_be_immutable
class PostWidgetProfile extends StatefulWidget {
  PostModal post;
  PostWidgetProfile({super.key, required this.post});

  @override
  State<PostWidgetProfile> createState() => _PostWidgetProfileState();
}

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

class _PostWidgetProfileState extends State<PostWidgetProfile> {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  bool isFollowing = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
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
          SizedBox(height: 4),
          Divider(),
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
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        final imageInfo = snapshot.data!;
        final aspectRatio = imageInfo.width / imageInfo.height;

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: CachedNetworkImage(
            imageUrl: post.imageUrl!,
            fit: BoxFit.contain,
            memCacheHeight: imageInfo.height,
            memCacheWidth: imageInfo.width,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.contain,
                    cacheHeight: imageInfo.height,
                    cacheWidth: imageInfo.width,
                  ),
                ),
            errorWidget: (context, url, error) =>
                Center(child: Icon(Icons.error)),
          ),
        );
      },
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
              displayRoundedSnackBar(context, "Coming soon");
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
        return Column(
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
                      String message = await UserServices().followingSystem(
                        post.userId,
                        isFollowing,
                      );
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
                        displayRoundedSnackBar(context, "Error happened");
                      }
                    }
                  },
                ),
              ],
            ),
            // SizedBox(height: 5),
          ],
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
