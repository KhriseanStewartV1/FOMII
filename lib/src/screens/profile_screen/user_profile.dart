import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:fomo_connect/src/widgets/post_widget_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class UserProfile extends StatefulWidget {
  DocumentSnapshot user;
  UserProfile({super.key, required this.user});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with SingleTickerProviderStateMixin {
  String following = '0';
  String followers = '0';
  String uniqueId = 'Tap to Generate';
  bool isFollowing = false;
  bool status = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCount();
    String uid = FirebaseAuth.instance.currentUser!.uid;
    getIsFollowing(uid);
    checkStatus();
  }

  void getIsFollowing(String uid) async {
    bool checkMessage = await UserServices().isFollowing(
      uid,
      widget.user['userId'],
    );
    if (checkMessage) {
      isFollowing = checkMessage;
    }
  }

  void getCount() async {
    final followerCount = await UserServices().getCount(
      widget.user['userId'],
      "followers",
    );
    final followingCount = await UserServices().getCount(
      widget.user['userId'],
      "following",
    );
    if (followingCount == null && followerCount == null) {
      return;
    }
    setState(() {
      followers = followerCount!;
      following = followingCount!;
    });
    print("Following: $following _ Followers: $followers");
  }

  String formatDateString(String? dateString) {
    if (dateString == null) return "Unknown";
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    } catch (_) {
      return dateString;
    }
  }

  void checkStatus() async {
    final userData = await UserServices().readUser(widget.user['userId']);
    try {
      if (userData!['status'] != null) {
        setState(() {
          status = true;
        });
      } else {
        status = false;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    String followMessage = '';
    String message = '';
    final userName = widget.user['name'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          MaterialButton(
            onPressed: () async {
              try {
                message = await UserServices().followingSystem(
                  widget.user['userId'],
                  isFollowing,
                );
                setState(() {
                  isFollowing = !isFollowing;
                  followMessage = message;
                });
                displayRoundedSnackBar(context, followMessage);
              } catch (e) {
                displayRoundedSnackBar(context, "An Error Happened");
              } finally {
                setState(() {
                  followMessage = '';
                });
              }
            },
            color: isFollowing ? Colors.grey : Colors.lightBlueAccent,
            focusColor: Colors.white,
            child: Text(
              isFollowing ? 'Following' : "Follow",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(userName),
                  SizedBox(height: 20),
                  _buildCount(),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                "Posts",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              _buildPostsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCount() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Text(
                "Followers",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                followers,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Text(
                "Following",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                following,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(String userName) {
    final uid = widget.user['userId'];
    return FutureBuilder(
      future: UserServices().readUser(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: const LoadingScreen());
        }
        if (!snap.hasData) {
          return const LogInScreen();
        }

        final doc = snap.data!;
        final createdAt = formatDateString(doc['createdAt']);
        final bio = doc.get('bio') ?? 'No Bio';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                _openFullScreenImage(
                  context,
                  'https://operaparallele.org/wp-content/uploads/2023/09/Placeholder_Image.png',
                );
              },
              child: _buildPicCard(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          createdAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [_buildBioField(bio)]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBioField(String bio) {
    final controller = TextEditingController(text: bio);
    return Expanded(
      child: TextFormField(
        readOnly: true,
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Add your bio...',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildPicCard(BuildContext context) {
    return StreamBuilder(
      stream: UserServices().userStream(
        widget.user['userId'],
      ), // listen to user updates
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(child: LoadingScreen()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _defaultPicCard(context); // fallback
        }

        final data = snapshot.data!;
        String? profilePic = data['profilePic'];

        // Determine if user is online/active (status)
        bool isActive =
            status; // assuming 'status' is a boolean variable in scope

        return Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Add gradient if active, else default border
                gradient: isActive
                    ? LinearGradient(
                        colors: [Colors.red, Colors.orange, Colors.yellow],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: !isActive
                    ? Border.all(color: Colors.grey.shade300, width: 3)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0), // space for the ring
                child: ClipOval(
                  child: profilePic == null || profilePic.isEmpty
                      ? _defaultPicCard(context)
                      : CachedNetworkImage(
                          imageUrl: profilePic,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          progressIndicatorBuilder: (context, child, progress) {
                            return Center(child: CircularProgressIndicator());
                          },
                          errorWidget: (context, error, object) {
                            return _defaultPicCard(context);
                          },
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// fallback default profile pic widget
  Widget _defaultPicCard(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(Icons.person, size: 90, color: Colors.white)),
    );
  }

  Widget _buildPostsList() {
    final uid = widget.user['userId'];

    return StreamBuilder(
      stream: PostServices().readYourPosts(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Center(child: Text("You haven't posted yet"));
        }

        final posts = snap.data!;
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: posts.length,
          itemBuilder: (context, index) =>
              PostWidgetProfile(post: posts[index]),
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
}
