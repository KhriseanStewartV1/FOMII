import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/others/image.dart';
import 'package:fomo_connect/src/database/storage/image.dart';
import 'package:fomo_connect/src/screens/auth/log_in_screen/log_in_screen.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:fomo_connect/src/widgets/post_widget_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool status = false;
  bool isLoading = false;
  XFile? file;
  String following = '0';
  String followers = '0';
  String uniqueId = 'Tap to Generate';
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _userNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _uniqueIdController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUser();
  }

  void loadUniqueId() async {
    try {
      final userData = await UserServices().readUser(uid);
      if (userData != null && userData['uniqueId'] != null) {
        setState(() {
          uniqueId = userData['uniqueId'];
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      print("Error getting uniqueId: $e");
    }
  }

  // void checkStatus() async {
  //   final userData = await UserServices().readUser(uid);
  //   try {
  //     if (userData!['status'] != null) {
  //       setState(() {
  //         status = true;
  //       });
  //     } else {
  //       status = false;
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  void getCount() async {
    final followerCount = await UserServices().getCount(uid, "followers");
    final followingCount = await UserServices().getCount(uid, "following");
    if (followingCount == null && followerCount == null) {
      return;
    }
    setState(() {
      followers = followerCount!;
      following = followingCount!;
    });
    print("Following: $following _ Followers: $followers");
  }

  void updateUser() async {
    Map<String, dynamic> dataToUpdate = {};

    if (_userNameController.text.isNotEmpty) {
      dataToUpdate['name'] = _userNameController.text;
      await FirebaseAuth.instance.currentUser!.updateDisplayName(
        _userNameController.text,
      );
    }
    if (_bioController.text.isNotEmpty) {
      dataToUpdate['bio'] = _bioController.text;
    }
    if (_uniqueIdController.text.isNotEmpty) {
      dataToUpdate['uniqueId'] = _uniqueIdController.text;
    }

    if (dataToUpdate.isNotEmpty) {
      await UserServices().updateUser(dataToUpdate);
      Navigator.pop(context);
      if (mounted) {
        displayRoundedSnackBar(context, "Reload the Page");
      }
    } else {
      displayRoundedSnackBar(context, "An error occurred");
    }
  }

  void loadUser() async {
    loadUniqueId();
    getCount();
    // checkStatus();
  }

  Future<void> pickImage() async {
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

      final url = await ImageService().uploadProfile(
        file: toFile(compressed),
        uid: uid,
      );

      await UserServices().updateUser({'profilePic': url});
    } catch (e) {
      debugPrint("❌ Error picking/uploading image: $e");
    }
  }

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
        uid: uid,
      );

      await UserServices().updateUser({'status': url});
    } catch (e) {
      debugPrint("❌ Error picking/uploading image: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? "Anonymous";

    void generateId() async {
      final userName = FirebaseAuth.instance.currentUser?.displayName ?? "User";
      final id = await UserServices().generateUniqueId(
        userName,
        checkUniqueIdExists,
      );
      setState(() {
        uniqueId = id;
      });
      await UserServices().updateUser({'uniqueId': id});
      print("Generated ID: $id");
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.settingScreen),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: pickImage,
                        child: Text(
                          "Upload Profile Picture",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      if (uniqueId == 'Tap to Generate')
                        TextButton(onPressed: generateId, child: Text(uniqueId))
                      else
                        GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(
                              ClipboardData(text: '@$uniqueId'),
                            );
                            displayRoundedSnackBar(
                              context,
                              "Copied to Clipboard",
                            );
                          },
                          child: Text(
                            "@$uniqueId",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  _buildCount(),
                ],
              ),
              const Divider(thickness: 1, height: 30),
              const SizedBox(height: 10),
              Text(
                "Posts",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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

  showUpdateUser(data) {
    return showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              right: 20,
              left: 20,
              top: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Update Profile",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Divider(),
                SizedBox(height: 10),

                /// Username
                Text(
                  "Name",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextField(
                  controller: _userNameController,
                  decoration: InputDecoration(
                    hintText: data['name'] ?? 'Enter your name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                /// Bio
                Text(
                  "Bio",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: data['bio'] == ''
                        ? 'Tell us about yourself...'
                        : data['bio'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                /// Unique ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Custom ID",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Tooltip(
                      message:
                          "This ID will be used for Mentions, profile URL and Messaging",
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _uniqueIdController,
                  decoration: InputDecoration(
                    hintText: data['uniqueId'] ?? 'Enter your custom ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                /// Submit Button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading ? null : updateUser,
                    child: isLoading
                        ? Center(child: LoadingScreen())
                        : Text(
                            "Update",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Upload Profile Picture",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Divider(),
              SizedBox(height: 4),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Picture'),
                onTap: () {
                  pickImage();
                  Navigator.pop(context);
                },
              ),
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
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                followers,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                following,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(String userName) {
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
        String createdAt = 'Loading Creation Date';
        try {
          String creationDate = formatDateString(doc['createdAt']);
          setState(() {
            createdAt = creationDate;
          });
        } catch (e) {
          print("Error getting creation date: $e");
        }
        final bio = doc.get('bio') ?? 'No Bio';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                if (doc['profilePic'] == '' || doc['profilePic'].isEmpty) {
                  _showProfileOptions();
                } else {
                  _openFullScreenImage(context, doc['profilePic']);
                }
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
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          createdAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                      Tooltip(
                        message:
                            "Account creation date cannot be changed or edited",
                        child: Icon(
                          Icons.question_mark,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [_buildBioField(bio, doc)]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBioField(String bio, data) {
    final controller = TextEditingController(text: bio);
    return Expanded(
      child: TextFormField(
        controller: controller,
        maxLines: null,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Add your bio...',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          suffixIcon: IconButton(
            onPressed: () => showUpdateUser(data),
            icon: const Icon(Icons.edit),
          ),
        ),
        onFieldSubmitted: (value) => UserServices().updateUser({'bio': value}),
      ),
    );
  }

  Widget _buildPicCard(BuildContext context) {
    return StreamBuilder(
      stream: UserServices().userStream(uid), // listen to user updates
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 100,
            height: 100,
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
              // Optional: overlay an "online" indicator dot
              // Positioned widget inside a Stack if needed
            ),
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _defaultPicCard(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(Icons.person, size: 80, color: Colors.white)),
    );
  }

  Widget _buildPostsList() {
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
