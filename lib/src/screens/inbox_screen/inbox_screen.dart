// ignore_for_file: unnecessary_null_comparison

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/firebase/chat/chat_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/modal/indox_modal.dart';
import 'package:fomo_connect/src/screens/inbox_screen/chat_screen.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getDeviceToken();
    print(FirebaseAuth.instance.currentUser!.uid);
  }

  String getRelativeTime(dynamic timestamp) {
    if (timestamp is int) {
      // Convert milliseconds timestamp to DateTime
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return timeago.format(dateTime);
    } else if (timestamp is DateTime) {
      return timeago.format(timestamp);
    } else {
      // fallback if data is missing or of unexpected type
      return '';
    }
  }

  Future<void> refresh() async {
    setState(() {});
  }

  void _getDeviceToken() async {
    NotificationService().pushToken(uid);
    bool status = await NotificationService().requestNotificationPermission();
    print(status);
  }

  String uid = FirebaseAuth.instance.currentUser!.uid;
  final _uIdSearchController = TextEditingController();
  String uIdSearch = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Inbox",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: showUsersSheet,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Inbox List
              Expanded(
                child: StreamBuilder<List<InboxItem>>(
                  stream: ChatService().listInboxV2(),
                  builder: (context, snapshot) {
                    print("current UID: $uid");
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingScreen());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No chats yet"));
                    }

                    final chats = snapshot.data!;
                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chatDoc = chats[index];
                        final otherUserId = chatDoc.otherUserId;
                        final chatId = chatDoc.chatId;
                        final nameFuture = ChatService().getUserName(
                          otherUserId,
                        );
                        String lastMessage = getRelativeTime(
                          chatDoc.lastMessageAt,
                        );
                        print(lastMessage);
                        return FutureBuilder<String>(
                          future: nameFuture,
                          builder: (context, nameSnapshot) {
                            final name = nameSnapshot.data ?? 'Unknown';

                            return GestureDetector(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserChat(
                                      userId: uid,
                                      chatId: chatId,
                                      recieverId: otherUserId,
                                    ),
                                  ),
                                );
                              },
                              child: _buildMessageCard(
                                otherUid: otherUserId,
                                name: name,
                                lastMessage: chatDoc.lastMessage,
                                time: lastMessage,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet with mutual followers
  showUsersSheet() {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
          child: Column(
            children: [
              Text(
                "Mutual Followers",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _uIdSearchController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  hintText: 'Search User ID',
                ),
                onChanged: (value) {
                  setState(() {
                    uIdSearch = _uIdSearchController.text;
                  });
                },
              ),
              SizedBox(height: 10),
              if (uIdSearch == '')
                _buildListofMutualFollowers()
              else
                Expanded(
                  child: StreamBuilder(
                    stream: UserServices().getUIdSearch(uIdSearch),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: LoadingScreen());
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Center(child: Text("No User by that ID"));
                      }
                      final user = snapshot.data!.docs;
                      return ListView(
                        children: user.map((follower) {
                          final followerData = follower.data();
                          final followerId = follower.id;
                          final name = followerData['name'] ?? "Unknown";

                          return GestureDetector(
                            onTap: () {
                              if (followerId != null) {
                                print(follower.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserChat(
                                      userId: uid,
                                      chatId: "${followerId}_$uid",
                                      recieverId: followerId,
                                    ),
                                  ),
                                );
                              } else {
                                displayFloatingSnackBar(
                                  context,
                                  "Unable to open chat, Data Missing",
                                );
                              }
                            },
                            child: _buildMessageCard(
                              name: name,
                              lastMessage: '',
                              otherUid: followerId,
                              time: '',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListofMutualFollowers() {
    return Expanded(
      child: StreamBuilder(
        stream: ChatService().listMutualFollowers(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingScreen());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Mutual Followers"));
          }

          final mutualFollowers = snapshot.data!;

          return ListView(
            children: mutualFollowers.map((follower) {
              final followerData = follower.data();
              final followerId = follower.id;
              final name = followerData['name'] ?? "Unknown";

              return GestureDetector(
                onTap: () {
                  if (followerId != null) {
                    print(follower.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserChat(
                          userId: uid,
                          chatId: "${followerId}_$uid",
                          recieverId: followerId,
                        ),
                      ),
                    );
                  } else {
                    displayFloatingSnackBar(
                      context,
                      "Unable to open chat, Data Missing",
                    );
                  }
                },
                child: _buildMessageCard(
                  name: name,
                  lastMessage: '',
                  otherUid: followerId,
                  time: '',
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMessageCard({
    required String otherUid,
    required String name,
    required String lastMessage,
    required String time,
  }) {
    return ListTile(
      title: Text(name),
      subtitle: Text(lastMessage),
      trailing: Text(time),
      leading: FutureBuilder(
        future: UserServices().readUser(otherUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(30),
              child: Icon(Icons.person, size: 30),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 30),
            );
          }
          final data = snapshot.data;
          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: data?['profilePic'],
              fit: BoxFit.cover,
              width: 50,
              height: 50,
              placeholder: (context, url) => CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 30),
              ),
              errorWidget: (context, url, error) {
                return CircleAvatar(
                  child: Center(
                    child: Icon(Icons.person, size: 30, color: Colors.black),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
