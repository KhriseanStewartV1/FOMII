import 'dart:convert';

class PostModal {
  final String userId; // ID of the user who created the post
  final String userName; // Name of the user
  final List<String> tags; // List of tags associated with the post
  final DateTime timestamp; // When the post was created
  final String? imageUrl; // Optional media URL (photo/video)
  final String uuid;
  final List<Map<String, dynamic>> richText; // Rich text delta
  final List<dynamic> likes; // list of user IDs
  final List<dynamic> reposts; // list of user IDs
  final List<dynamic> mentions; // list of comment IDs

  PostModal({
    required this.userId,
    required this.userName,
    required this.tags,
    required this.timestamp,
    required this.uuid,
    required this.richText,
    this.imageUrl,
    List<dynamic>? likes,
    List<dynamic>? reposts,
    List<dynamic>? mentions,
  })  : likes = likes ?? [],
        reposts = reposts ?? [],
        mentions = mentions ?? [];

  // Convert to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'postId': uuid,
      'userId': userId,
      'userName': userName,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
      'mediaUrl': imageUrl,
      'likes': likes,
      'reposts': reposts,
      'mentions': mentions,
      'richText': richText, // store as List<Map>
    };
  }

  // Create an instance from Map
  factory PostModal.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parsedRichText = [];

    if (map['richText'] != null) {
      if (map['richText'] is String) {
        // Handle case where it's stored as JSON string
        parsedRichText = List<Map<String, dynamic>>.from(jsonDecode(map['richText']));
      } else if (map['richText'] is List) {
        // Normal case (already a List of Maps)
        parsedRichText = List<Map<String, dynamic>>.from(map['richText']);
      }
    }

    return PostModal(
      uuid: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      imageUrl: map['mediaUrl'],
      likes: List<dynamic>.from(map['likes'] ?? []),
      reposts: List<dynamic>.from(map['reposts'] ?? []),
      mentions: List<dynamic>.from(map['mentions'] ?? []),
      richText: parsedRichText,
    );
  }

  factory PostModal.fromFirestore(Map<String, dynamic> data) {
    List<Map<String, dynamic>> parsedRichText = [];

    if (data['richText'] != null) {
      if (data['richText'] is String) {
        // If stored as a JSON string
        parsedRichText = List<Map<String, dynamic>>.from(jsonDecode(data['richText']));
      } else if (data['richText'] is List) {
        // If stored as List of maps
        parsedRichText = List<Map<String, dynamic>>.from(data['richText']);
      }
    }

    return PostModal(
      uuid: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      imageUrl: data['mediaUrl'],
      likes: List<dynamic>.from(data['likes'] ?? []),
      reposts: List<dynamic>.from(data['reposts'] ?? []),
      mentions: List<dynamic>.from(data['mentions'] ?? []),
      richText: parsedRichText,
    );
  }
}
