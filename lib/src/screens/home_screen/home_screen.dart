import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/provider/post_provider.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/screens/notifications/notification_screen.dart';
import 'package:fomo_connect/src/widgets/post_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<PostModal>>? _postSubscription;
  int selectedTab = 0;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  final List<PostModal> allPosts = []; // Combined list of posts
  bool isLoadingMore = false; // to prevent multiple fetches
  DocumentSnapshot? lastDocument; // last doc for pagination
  final ScrollController _scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();

  Future<void> refresh() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    // 2️⃣ Shuffle the posts
    final posts = postProvider.posts.values.toList();
    posts.shuffle();

    // 3️⃣ Update provider with the shuffled posts
    postProvider.setPosts(posts);

    // 4️⃣ Small delay to let RefreshIndicator show animation smoothly
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _getDeviceToken() async {
    NotificationService().pushToken(uid);
    bool status = await NotificationService().requestNotificationPermission();
    print(status);
  }

  @override
  void initState() {
    super.initState();
    _getDeviceToken();
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    postProvider.listenToPostUpdates(); // start listening for real-time updates
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore) {
        PostServices().fetchMorePosts(lastDocument!);
      }
    });
  }

  // ignore: unused_element
  void _listenPosts() {
    _postSubscription = PostServices().readPosts().listen((posts) {
      if (!mounted) return;
      final postProvider = Provider.of<PostProvider>(context, listen: false);

      // Update only if posts changed
      final currentIds = postProvider.posts.keys.toSet();
      final newIds = posts.map((e) => e.uuid).toSet();
      if (!setEquals(currentIds, newIds)) {
        postProvider.setPosts(
          posts,
        ); // make sure setPosts calls notifyListeners()
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _postSubscription?.cancel(); // ✅ cancel stream to avoid unmounted errors
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.onSurface,
        leading: Center(
          child: Text(
            "FOMII",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: _buildToggle(),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
            ),
            icon: Icon(FeatherIcons.bell),
          ),
        ],
      ),
      body: UpgradeAlert(
        barrierDismissible: false,
        showLater: false,
        showIgnore: false,
        dialogStyle: Platform.isIOS
            ? UpgradeDialogStyle.cupertino
            : UpgradeDialogStyle.material,
        upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(hours: 1),
          debugLogging: kDebugMode,
        ),
        child: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: refresh,
          child: Consumer<PostProvider>(
            builder: (context, postProvider, _) {
              final posts = postProvider.posts.values.toList();
              if (posts.isEmpty) {
                return Center(child: Text("No posts"));
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Stack(
                  children: [
                    if (selectedTab == 0) Column(
                      children: [
                                TextFormField(
                                  controller: searchController,
                            onChanged: (query) {
                              final postProvider = Provider.of<PostProvider>(
                                context,
                                listen: false,
                              );
                              final filtered = postProvider.posts.values
                                  .where(
                                    (p) => p.postText.toLowerCase().contains(
                                      query.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                              setState(() {
                                // Show filtered list
                              });
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 10,
                              ),
                              hint: Text(
                                "Search...",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        Expanded(child: _buildStreamPosts(posts)),
                      ],
                    ),
                    if (selectedTab == 1)
                      StreamBuilder(
                        stream: PostServices().getFollowingPosts(uid),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) {
                            return Center(child: Text("Not following anyone"));
                          }
                          final data = snapshot.data;
                          if (data!.isEmpty) {
                            return Center(child: Text("Not Followers Post"));
                          }
                          return _buildStreamPosts(data);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: CircleBorder(),
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.addPost);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Function to load older posts
  Future<void> loadMorePosts() async {
    if (lastDocument == null && allPosts.isNotEmpty) {
      // No more posts to load
      return;
    }
    setState(() {
      isLoadingMore = true;
    });

    final morePosts = await PostServices().fetchMorePosts(lastDocument!);
    if (morePosts.isNotEmpty) {
      setState(() {
        allPosts.addAll(morePosts);
        lastDocument;
      });
    }
    setState(() {
      isLoadingMore = false;
    });
  }

  // Fetch initial posts (latest 10)
  Widget buildStreamBuilder() {
    return StreamBuilder<List<PostModal>>(
      stream: PostServices().readLatestPosts(), // your stream for newest posts
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Replace existing posts with latest
        final latestPosts = snapshot.data!;
        allPosts.clear();
        allPosts.addAll(latestPosts);

        return ListView.builder(
          controller: _scrollController,
          itemCount: allPosts.length,
          itemBuilder: (context, index) {
            final post = allPosts[index];
            return ListTile(
              title: Text(post.postText), // assuming PostModal has title
              // your post widget here
            );
          },
        );
      },
    );
  }

  Widget _buildStreamPosts(List<PostModal> data) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(),
      itemCount: data.length,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, index) {
        final PostModal post = data[index];
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 1),
          child: PostWidget(post: post),
        );
      },
    );
  }

  Widget _buildToggle() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedTab = 0;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: selectedTab == 0
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 0.0),
            ),
            child: Text(
              "For You",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: selectedTab == 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                selectedTab = 1;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: selectedTab == 1
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 0.0),
            ),
            child: Text(
              "Following",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: selectedTab == 1
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
