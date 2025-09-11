import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/router.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/provider/post_provider.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/screens/notifications/notification_screen.dart';
import 'package:fomo_connect/src/widgets/posts/post_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<PostModal>>? _postSubscription;
  int selectedTab = 0;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController searchController = TextEditingController();
  List<PostModal> filteredPost = [];

  final List<PostModal> _posts = [];
  bool _loadingMore = false; // to prevent multiple fetches
  DocumentSnapshot? _lastDoc; // last doc for pagination
  final ScrollController _scrollController = ScrollController();

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

  Future<void> _loadMore() async {
    if (_loadingMore) return;

    setState(() => _loadingMore = true);

    final batchProvider = Provider.of<BatchPostProvider>(context, listen: false);
    final currentPosts = batchProvider.posts.values.toList();

    // Determine the last document from Firestore
    if (_lastDoc == null && currentPosts.isNotEmpty) {
      final lastPost = currentPosts.last;
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(lastPost.uuid)
          .get();
      _lastDoc = snap;
    }

    if (_lastDoc == null) {
      setState(() => _loadingMore = false);
      return;
    }

    final more = await BatchPostServices().fetchMorePosts(_lastDoc!, limit: 10);

    if (more.isNotEmpty) {
      batchProvider.addPosts(more..shuffle());

      // update pagination pointer to new last doc
      final lastPost = more.last;
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(lastPost.uuid)
          .get();
      _lastDoc = snap;
    }

    setState(() => _loadingMore = false);
  }


  @override
  void initState() {
    super.initState();
    _getDeviceToken();
    final batchProvider = Provider.of<BatchPostProvider>(context, listen: false);
    BatchPostServices().readLatestPosts(limit: 10).listen((batch) {
      if (batch.isNotEmpty) {

      batchProvider.setPosts(batch);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loadingMore) {
        _loadMore();
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
    print(AuthService().user!.emailVerified);
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.symmetric(horizontal: 8),
        elevation: 0,
        leading: AspectRatio(aspectRatio: 1, child: Image.asset('assets/fomo-bgremove.png')),
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
      body: Consumer<BatchPostProvider>(
      builder: (context, batchProvider, _) {
        final posts = batchProvider.posts.values.toList();
        if (posts.isEmpty) return Center(child: CircularProgressIndicator());

        return RefreshIndicator(
          onRefresh: () async {
            posts.shuffle();
            batchProvider.setPosts(posts);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: selectedTab == 0 ? Column(
              children: [
                TextFormField(
                  controller: searchController,
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
                    border: InputBorder.none
                  ),
                  onChanged: (query) {
                    final postProvider = Provider.of<BatchPostProvider>(
                      context,
                      listen: false,
                    );
                    final allPosts = postProvider.posts.values.toList();
    
                    setState(() {
                      if (query.isEmpty) {
                        filteredPost = allPosts; // reset to all
                      } else {
                        final lowerQuery = query.toLowerCase();
    
                        filteredPost = allPosts.where((p) {
                          final matchesText = p.richText.where( (element) {
                            if (element.containsKey('insert')) {
                              final insert = element['insert'];
                                if (insert is String) {
                                  return insert.toLowerCase().contains(lowerQuery);
                                }
                            }
                            return false;
                          }).isNotEmpty;
                            final matchesUser = p.userName.toLowerCase().contains(lowerQuery);
                            final matchesHashtag = p.tags.any(
                              (tag) => tag.toLowerCase().contains(lowerQuery),
                            );
    
                            return matchesText || matchesUser || matchesHashtag;
                        }).toList();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10,),
                Expanded(child: searchController.text.isNotEmpty ? _buildStreamPosts(filteredPost) : _buildStreamPosts(posts)),
              ],
            ) : StreamBuilder(
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
          ),
        );
      }
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

  // ignore: unused_element
  Widget _buildBody() {
    return RefreshIndicator(
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
                          final allPosts = postProvider.posts.values.toList();
    
                          setState(() {
                            if (query.isEmpty) {
                              filteredPost = allPosts; // reset to all
                            } else {
                              final lowerQuery = query.toLowerCase();
    
                              filteredPost = allPosts.where((p) {
                                final matchesText = p.richText.where( (element) {
                                  if (element.containsKey('insert')) {
                                    final insert = element['insert'];
                                    if (insert is String) {
                                      return insert.toLowerCase().contains(lowerQuery);
                                    }
                                  }
                                  return false;
                                }).isNotEmpty;
                                final matchesUser = p.userName.toLowerCase().contains(lowerQuery);
                                final matchesHashtag = p.tags.any(
                                  (tag) => tag.toLowerCase().contains(lowerQuery),
                                );
    
                                return matchesText || matchesUser || matchesHashtag;
                              }).toList();
                            }
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
                    Expanded(child: searchController.text.isNotEmpty ? _buildStreamPosts(filteredPost) : _buildStreamPosts(posts)),
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
