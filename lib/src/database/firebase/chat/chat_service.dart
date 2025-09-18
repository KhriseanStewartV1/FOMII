import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fomo_connect/src/modal/indox_modal.dart';

final _instance = FirebaseFirestore.instance;

class ChatService {
  final _usersCollection = _instance.collection('users');
  final _chatsCollection = _instance.collection('chats');
  String uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamMessages(
    String chatId,
  ) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String message,
  ) async {
    // Get or create chat consistently
    final chatRef = await getOrCreateChat(senderId, receiverId);

    final messagesRef = chatRef.collection('messages');

    // Add the message
    await messagesRef.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': DateTime.now(),
      'read': false,
      'participates': [senderId, receiverId],
    });

    // Update chat metadata
    await chatRef.set({
      'lastMessage': message,
      'timestamp': FieldValue.serverTimestamp(),
      'userId1': senderId,
      'userId2': receiverId,
    }, SetOptions(merge: true));
  }

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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getChatInfo(String chatId) {
    return _chatsCollection.doc(chatId).snapshots();
  }

  /// Get list of users who follow each other (mutuals)
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> listMutualFollowers(
    String userId,
  ) {
    return _usersCollection.doc(userId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return [];

      List<dynamic> following = userDoc.data()?['following'] ?? [];

      // For each user the current user follows, check if they follow back
      final mutuals = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (String followedId in following.cast<String>()) {
        final followedUserDoc = await _usersCollection.doc(followedId).get();

        if (!followedUserDoc.exists) continue;

        List<dynamic> followedUserFollowing =
            followedUserDoc.data()?['following'] ?? [];

        if (followedUserFollowing.contains(userId)) {
          // Add this mutual user's snapshot
          final snapshot = await _usersCollection.doc(followedId).get();
          if (snapshot.exists) {
            // Convert to QueryDocumentSnapshot-like object
            final querySnap = await _usersCollection
                .where(FieldPath.documentId, isEqualTo: followedId)
                .get();
            if (querySnap.docs.isNotEmpty) {
              mutuals.add(querySnap.docs.first);
            }
          }
        }
      }
      return mutuals;
    });
  }

  Stream<List<InboxItem>> listInboxV2() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InboxItem.fromDocument(doc, uid))
              .toList(),
        );
  }

  Stream<int> unreadMessagesCount(String uid) {
    return _chatsCollection
        .where('participants', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          int totalUnread = 0;

          for (var chat in snapshot.docs) {
            final messages = await chat.reference
                .collection('messages')
                .where('receiverId', isEqualTo: uid)
                .where('read', isEqualTo: false)
                .get();

            totalUnread += messages.docs.length;
          }

          return totalUnread;
        });
  }

  Future<void> markMessagesAsRead(String chatId, String uid) async {
    final messagesRef = _chatsCollection.doc(chatId).collection('messages');

    final unreadMessages = await messagesRef
        .where('receiverId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'read': true});
    }
  }

  /// Get or create chat between two users
  Future<DocumentReference<Map<String, dynamic>>> getOrCreateChat(
    String userId1,
    String userId2,
  ) async {
    // Generate a consistent chat ID based on user IDs (lex order)
    List<String> ids = [userId1, userId2]..sort();
    String chatId = ids.join('_');

    DocumentReference<Map<String, dynamic>> chatRef = _chatsCollection.doc(
      chatId,
    );

    // Check if chat exists
    DocumentSnapshot<Map<String, dynamic>> chatSnap = await chatRef.get();
    if (!chatSnap.exists) {
      // Create new chat document
      await chatRef.set({
        'participants': ids,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatRef;
  }
}
