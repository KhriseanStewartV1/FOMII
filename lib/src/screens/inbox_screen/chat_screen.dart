import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/chat/chat_service_rtdb.dart';
import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/screens/profile_screen/user_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  final String currentUserId = AuthService().user!.uid;
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

  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await UserServices().readUser(uid);
    if (doc == null || !doc.exists) {
      return null;
    } else {
      return doc.data()!;
    }
  }

  void _getRecieverToken() async {
    token = await getRecieverDToken();
    username = await getUserName();
  }

  Future<void> _fetchOtherUserName() async {
    String name = await ChatServiceRTDB().getUserName(widget.recieverId);
    setState(() {
      otherUserName = name;
    });
  }

  // Improved date header formatting with WhatsApp-style logic
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    // Calculate difference in days
    final difference = today.difference(msgDate).inDays;

    if (msgDate == today) {
      return "Today";
    } else if (msgDate == yesterday) {
      return "Yesterday";
    } else if (difference < 7) {
      // Show day of week for messages within the last week
      return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
    } else if (date.year == now.year) {
      // Show month and day for messages within the current year
      return DateFormat('MMM d').format(date); // Jan 15
    } else {
      // Show full date for messages from previous years
      return DateFormat('MMM d, yyyy').format(date); // Jan 15, 2023
    }
  }

  // Helper method to check if two dates are on different days
  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final String chatId = widget.chatId;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: StreamBuilder(
                stream: ChatServiceRTDB().streamMessagesV2(chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;

                  // Mark unread messages as read
                  ChatServiceRTDB().markMessagesAsRead(chatId);

                  return ListView.builder(
                    reverse: false,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['senderId'] == currentUserId;
                      final msgTime = DateTime.fromMillisecondsSinceEpoch(
                        msg['timestamp'],
                      );

                      // Check if we should show date header
                      bool showDateHeader = false;
                      if (index == 0) {
                        // Always show date header for the first (oldest) message
                        showDateHeader = true;
                      } else {
                        // Compare with previous message
                        final prevMsg = messages[index - 1];
                        final prevMsgTime = DateTime.fromMillisecondsSinceEpoch(
                          prevMsg['timestamp'],
                        );

                        // Show header if messages are on different days
                        showDateHeader = _isDifferentDay(msgTime, prevMsgTime);
                      }

                      return Column(
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _formatDateHeader(msgTime),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 12,
                            ),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.75,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.lightBlueAccent
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(12),
                                        topRight: const Radius.circular(12),
                                        bottomLeft: isMe
                                            ? const Radius.circular(12)
                                            : const Radius.circular(4),
                                        bottomRight: isMe
                                            ? const Radius.circular(4)
                                            : const Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      msg['message'],
                                      style: GoogleFonts.poppins(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      DateFormat('h:mm a').format(msgTime),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF128C7E), // WhatsApp green
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: isSendingMessage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || isSendingMessage) return;

    setState(() => isSendingMessage = true);
    messageController.clear();

    try {
      if (token == null) {
        return;
      }

      await ChatServiceRTDB().sendMessage(
        currentUserId,
        widget.recieverId,
        trimmedMessage,
      );

      await NotificationService.sendPushNotificationv2(
        body: trimmedMessage,
        deviceToken: token!,
        title: username ?? 'Unknown',
        context: context,
        receiverUid: widget.recieverId,
      );

      HapticFeedback.lightImpact();
    } catch (e) {
      // Handle error appropriately
      print('Error sending message: $e');
    } finally {
      setState(() => isSendingMessage = false);
    }
  }

  PreferredSize _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: FutureBuilder(
          future: getUserDoc(widget.recieverId),
          builder: (context, snap) {
            return GestureDetector(
              onTap: snap.hasData && snap.data != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfile(user: snap.data),
                        ),
                      );
                    }
                  : null,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        snap.hasData && snap.data?['profilePic'] != null
                        ? NetworkImage(snap.data!['profilePic'])
                        : null,
                    child: snap.hasData && snap.data?['profilePic'] != null
                        ? null
                        : const Icon(Icons.person, color: Colors.white),
                    backgroundColor: Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      otherUserName ?? 'Loading...',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
