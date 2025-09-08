

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/chat/chat_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/screens/inbox_screen/chat_screen.dart';
import 'package:fomo_connect/src/widgets/contact_list.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomSheetScreen extends StatefulWidget {
  BottomSheetScreen({super.key});

  @override
  State<BottomSheetScreen> createState() => _BottomSheetScreenState();
}

class _BottomSheetScreenState extends State<BottomSheetScreen> {
  final _uIdSearchController = TextEditingController();
  String uid = AuthService().user!.uid;
  int selectedTab = 0;
  String uIdSearch = '';
  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
          child: Column(
            children: [
              Text(
                "Start Chatting",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _uIdSearchController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 10,
                  ),
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
              _buildToggle(),
              if (selectedTab == 0)
                if(_uIdSearchController.text.isEmpty)
                _buildListofMutualFollowers()
                else 
                _buildSearchList()
              else
                ContactList()
            ],
          ),
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
              print(name);

              return GestureDetector(
                onTap: () {
                  // ignore: unnecessary_null_comparison
                  if (followerId != null) {
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
              "Mutuals",
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
              "Contacts",
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

  Widget _buildSearchList() {
    return Expanded(
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
                            // ignore: unnecessary_null_comparison
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
}