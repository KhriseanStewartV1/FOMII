import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/provider/post_provider.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/widgets/constants.dart';
import 'package:fomo_connect/src/widgets/default_card.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/mention_text_field.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class PostBottomButtons extends StatefulWidget {
  PostModal post;
  PostBottomButtons({super.key, required this.post});

  @override
  State<PostBottomButtons> createState() => _PostBottomButtonsState();
}

final _commentController = TextEditingController();

class _PostBottomButtonsState extends State<PostBottomButtons>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().user!.uid;

    final batchProvider = Provider.of<BatchPostProvider>(context);
    final posts = batchProvider.posts[widget.post.uuid];
    if (posts == null) {
      return const SizedBox.shrink();
    }
    final isLiked = posts.likes.contains(uid);
    final isReposted = posts.reposts.contains(uid);
    final likesCount = posts.likes.length;
    final repostsCount = posts.reposts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: StreamBuilder(
        stream: PostServices().numberOfComments(posts.uuid),
        builder: (context, snap) {
          if (!snap.hasData) {
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    Provider.of<BatchPostProvider>(
                      context,
                      listen: false,
                    ).toggleLike(widget.post.uuid, uid, context);
                    String? deviceToken = await NotificationService().getToken(
                      widget.post.userId,
                    );
                    if (deviceToken != null && isLiked != true) {
                      await NotificationService.sendPushNotificationv2(
                        deviceToken: deviceToken,
                        title: "Liked",
                        body: "Someone Liked your post!",
                        context: context,
                        receiverUid: widget.post.userId,
                      );
                    }
                    HapticFeedback.lightImpact();
                  },
                  child: _buildBottomPostOptions(
                    "${likesCount == 0 ? 'Like' : likesCount}",
                    Icon(
                      size: 24,
                      isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: isLiked
                          ? hexToColor("#FF5252")
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
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    Provider.of<BatchPostProvider>(
                      context,
                      listen: false,
                    ).toggleRepost(widget.post.uuid, uid, context);
                    String? deviceToken = await NotificationService().getToken(
                      widget.post.userId,
                    );
                    if (deviceToken != null && !isReposted) {
                      await NotificationService.sendPushNotificationv2(
                        deviceToken: deviceToken,
                        title: "Repost",
                        body: "Someone Reposted your post!",
                        context: context,
                        receiverUid: widget.post.userId,
                      );
                    }
                    HapticFeedback.lightImpact();
                  },
                  child: _buildBottomPostOptions(
                    "${repostsCount == 0 ? 'Repost' : repostsCount}",
                    Icon(
                      FeatherIcons.repeat,
                      size: 24,
                      color: isReposted
                          ? Colors.blue
                          : Colors.lightBlueAccent.shade200,
                    ),
                  ),
                ),
              ],
            );
          }
          final commentNum = snap.data?.docs;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  backgroundColor: Colors.transparent,
                ),
                onPressed: () async {
                  Provider.of<BatchPostProvider>(
                    context,
                    listen: false,
                  ).toggleLike(widget.post.uuid, uid, context);
                  String? deviceToken = await NotificationService().getToken(
                    widget.post.userId,
                  );
                  if (deviceToken != null && isLiked != true) {
                    await NotificationService.sendPushNotificationv2(
                      deviceToken: deviceToken,
                      title: "Liked",
                      body: "Someone Liked your post!",
                      context: context,
                      receiverUid: widget.post.userId,
                    );
                  }
                  HapticFeedback.lightImpact();
                },
                child: _buildBottomPostOptions(
                  "${likesCount == 0 ? 'Like' : likesCount}",
                  Icon(
                    size: 24,
                    isLiked ? Icons.favorite : Icons.favorite_outline,
                    color: isLiked
                        ? hexToColor("#FF5252")
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  showCommentModal();
                },
                child: _buildBottomPostOptions(
                  "${commentNum?.length ?? ''}",
                  Icon(FeatherIcons.messageSquare, size: 24),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  backgroundColor: Colors.transparent,
                ),
                onPressed: () async {
                  Provider.of<BatchPostProvider>(
                    context,
                    listen: false,
                  ).toggleRepost(widget.post.uuid, uid, context);
                  String? deviceToken = await NotificationService().getToken(
                    widget.post.userId,
                  );
                  if (deviceToken != null && !isReposted) {
                    await NotificationService.sendPushNotificationv2(
                      deviceToken: deviceToken,
                      title: "Repost",
                      body: "Someone Reposted your post!",
                      context: context,
                      receiverUid: widget.post.userId,
                    );
                  }
                  HapticFeedback.lightImpact();
                },
                child: _buildBottomPostOptions(
                  "${repostsCount == 0 ? 'Repost' : repostsCount}",
                  Icon(
                    FeatherIcons.repeat,
                    size: 24,
                    color: isReposted
                        ? Colors.blue
                        : Colors.lightBlueAccent.shade200,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomPostOptions(String text, Widget icon) {
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
                          ? DefaultCard()
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
                                return DefaultCard();
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

  String getFormattedDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(dateTime);
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

  void userComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;
    final userData = await UserServices().readUser(AuthService().user!.uid);
    final autherData = await UserServices().readUser(widget.post.userId);
    final deviceToken = autherData!['token'];
    print("device token: $deviceToken");
    if (userData == null) return; // handle error if needed
    _commentController.clear(); // Clear input after sending

    await PostServices().addComment(
      commentText,
      AuthService().user!.uid,
      userData['profilePic'],
      DateTime.now(),
      userData['name'],
      widget.post.uuid,
    );
    await NotificationService.sendPushNotificationv2(
      deviceToken: deviceToken,
      title: "${userData['name']} left a comment",
      body: commentText,
      context: context,
      receiverUid: widget.post.userId,
    );
    HapticFeedback.mediumImpact();
  }
}
