import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fomo_connect/src/modal/indox_modal.dart';

class ChatServiceRTDB {
  final _db = FirebaseDatabase.instance.ref();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  /// Stream messages for a chat in real-time, returning raw maps
  Stream<List<Map<String, dynamic>>> streamMessagesV2(String chatId) {
    return FirebaseDatabase.instance
        .ref()
        .child('chats/$chatId/messages')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;

          if (data == null) return [];

          // Convert to list of maps
          final messages = data.entries.map((entry) {
            return Map<String, dynamic>.from(entry.value);
          }).toList();

          // Sort by timestamp ascending
          messages.sort((a, b) {
            final t1 = a['timestamp'] ?? 0;
            final t2 = b['timestamp'] ?? 0;
            return t1.compareTo(t2);
          });

          return messages;
        });
  }

  /// Stream of messages for a chat
  Stream<List<InboxItem>> streamMessages(String chatId) {
    return _db
        .child('chats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final messagesMap =
              event.snapshot.value as Map<dynamic, dynamic>? ?? {};
          return messagesMap.entries.map((e) {
              final data = Map<String, dynamic>.from(e.value);
              return InboxItem.fromMap(data, chatId, uid);
            }).toList()
            ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        });
  }

  /// Send a message
  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String message,
  ) async {
    final chatRef = await getOrCreateChat(senderId, receiverId);
    final messagesRef = chatRef.child('messages');
    final newMsgRef = messagesRef.push();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await newMsgRef.set({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'read': false,
      'participants': [senderId, receiverId],
    });

    await chatRef.update({
      'lastMessage': message,
      'timestamp': timestamp,
      'participants': [senderId, receiverId],
    });
  }

  /// Get username
  Future<String> getUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return data['name'] ?? 'Unknown User';
    } else {
      return 'Unknown User';
    }
  }

  /// Stream inbox (last message per chat)
  Stream<List<InboxItem>> listInbox() {
    return _db.child('chats').orderByChild('participants').onValue.map((event) {
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final inbox = <InboxItem>[];
      chatsMap.forEach((key, value) {
        final data = Map<String, dynamic>.from(value);
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(uid)) {
          inbox.add(InboxItem.fromMap(data, key, uid));
        }
      });
      inbox.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return inbox;
    });
  }

  /// Count unread messages
  Stream<int> unreadMessagesCount() {
    return _db.child('chats').onValue.map((event) {
      int totalUnread = 0;
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      chatsMap.forEach((chatId, chatData) {
        final chat = Map<String, dynamic>.from(chatData);
        final messages = chat['messages'] as Map<dynamic, dynamic>? ?? {};
        messages.forEach((msgId, msgData) {
          final msg = Map<String, dynamic>.from(msgData);
          if (msg['receiverId'] == uid && msg['read'] == false) {
            totalUnread++;
          }
        });
      });
      return totalUnread;
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final messagesRef = _db.child('chats/$chatId/messages');
    final snapshot = await messagesRef.get();
    final msgs = snapshot.value as Map<dynamic, dynamic>? ?? {};
    for (var entry in msgs.entries) {
      final key = entry.key;
      final msg = Map<String, dynamic>.from(entry.value);
      if (msg['receiverId'] == uid && msg['read'] == false) {
        await messagesRef.child(key).update({'read': true});
      }
    }
  }

  /// Create or get chat reference
  Future<DatabaseReference> getOrCreateChat(
    String userId1,
    String userId2,
  ) async {
    final ids = [userId1, userId2]..sort();
    final chatId = ids.join('_');
    final chatRef = _db.child('chats/$chatId');
    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'participants': ids,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    return chatRef;
  }
}
