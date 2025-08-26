import 'package:cloud_firestore/cloud_firestore.dart';

class InboxItem {
  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final DateTime lastMessageAt;

  InboxItem({
    required this.chatId,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory InboxItem.fromDocument(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;

    final List<dynamic> participants = data['participants'] ?? [];
    String otherUserId;

    // Find the other participant
    if (participants.contains(currentUserId)) {
      // Remove current user to get the other
      otherUserId = participants.firstWhere((id) => id != currentUserId);
    } else {
      // Fallback: if current user not in participants, set otherUserId to empty or handle differently
      otherUserId = '';
    }

    // Parse lastMessage
    final String lastMessage = data['lastMessage'] ?? '';

    // Parse lastMessageAt, which could be a Timestamp
    final timestamp = data['lastMessageAt'];
    DateTime lastMessageAt;
    if (timestamp is Timestamp) {
      lastMessageAt = timestamp.toDate();
    } else if (timestamp is int) {
      lastMessageAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      lastMessageAt = DateTime.now(); // fallback
    }

    // Use chatId from document ID or from data
    final chatId = doc.id;

    return InboxItem(
      chatId: chatId,
      otherUserId: otherUserId,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
    );
  }
}
