import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/chat/chat_service.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/widgets/loading_screen.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'package:http/http.dart' as http;

class UserChat extends StatefulWidget {
  final String userId; // current user ID
  final String chatId; // chat ID
  final String recieverId; // other user ID

  const UserChat({
    super.key,
    required this.userId,
    required this.chatId,
    required this.recieverId,
  });

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> {
  final TextEditingController messageController = TextEditingController();
  String? otherUserName;
  String? username;
  bool isSendingMessage = false;
  final String currentUserId = AuthService().user!.uid; // ✅ use this everywhere
  String? token;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserName();
    _getRecieverToken();
  }

  Future<String?> getRecieverDToken() async {
    final doc = await UserServices().readUser(widget.recieverId);
    if (doc == null) {
      return null;
    } else {
      return doc['token'];
    }
  }

  Future<String?> getUserName() async {
    final doc = await UserServices().readUser(currentUserId);
    if (doc == null) {
      return null;
    } else {
      return doc['name'];
    }
  }

  void _getRecieverToken() async {
    token = await getRecieverDToken();
    username = await getUserName();
  }

  Future<void> _fetchOtherUserName() async {
    String name = await ChatService().getUserName(widget.recieverId);
    setState(() {
      otherUserName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String chatId = widget.chatId;

    return Scaffold(
      appBar: AppBar(title: Text(otherUserName ?? 'Loading...')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: ChatService().streamMessages(chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;

                  return ListView.builder(
                    reverse: true, // ✅ only this, no manual reversing
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index]; // ✅ direct index
                      final data = msg.data();
                      final isMe = data['senderId'] == currentUserId;

                      return ListTile(
                        title: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.teal[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data['message'],
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        subtitle: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: data['timestamp'] != null
                              ? Text(
                                  DateFormat(
                                    'hh:mm a',
                                  ).format(data['timestamp'].toDate()),
                                  style: const TextStyle(fontSize: 10),
                                )
                              : const SizedBox(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: isSendingMessage
                        ? const LoadingScreen()
                        : const Icon(Icons.send, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                    onPressed: () async {
                      final message = messageController.text.trim();
                      print(otherUserName!);
                      if (message.isNotEmpty) {
                        setState(
                          () => isSendingMessage = true,
                        ); // ✅ show loader
                        messageController.clear();
                        if (token == null) {
                          setState(() => isSendingMessage = false);
                          return;
                        }
                        await ChatService().sendMessage(
                          currentUserId,
                          widget.recieverId,
                          message,
                        ); // ✅ fixed

                        await NotificationService.sendPushNotificationv2(
                          body: message,
                          deviceToken: token!,
                          title: username ?? 'Unknown',
                        );
                        HapticFeedback.lightImpact();
                        setState(() => isSendingMessage = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
