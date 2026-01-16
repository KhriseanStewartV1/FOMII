import 'dart:convert';
import 'package:fomo_connect/src/modal/event_model.dart';

class PostModal {
  final String postIn;
  final String userId;
  final String userName;
  final List<String> tags;
  final DateTime timestamp;
  final String uuid;
  final List<Map<String, dynamic>> richText;
  final List<dynamic> likes;
  final List<dynamic> reposts;
  final List<dynamic> mentions;
  final List<Map<String, dynamic>> media; // {url, type}
  final EventModel? event;

  PostModal({
    required this.userId,
    required this.postIn,
    required this.userName,
    required this.tags,
    required this.timestamp,
    required this.uuid,
    required this.richText,
    required this.media,
    this.event,
    List<dynamic>? likes,
    List<dynamic>? reposts,
    List<dynamic>? mentions,
  }) : likes = likes ?? [],
       reposts = reposts ?? [],
       mentions = mentions ?? [];

  /// Convert to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'postId': uuid,
      'postIn': postIn,
      'userId': userId,
      'userName': userName,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
      'media': media,
      'likes': likes,
      'reposts': reposts,
      'mentions': mentions,
      'richText': richText,
      'event': event?.toMap(), // <-- properly convert EventModel
    };
  }

  /// Create an instance from Map
  factory PostModal.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parsedRichText = [];

    if (map['richText'] != null) {
      if (map['richText'] is String) {
        parsedRichText = List<Map<String, dynamic>>.from(
          jsonDecode(map['richText']),
        );
      } else if (map['richText'] is List) {
        parsedRichText = List<Map<String, dynamic>>.from(map['richText']);
      }
    }

    return PostModal(
      postIn: map['postIn'] ?? '',
      uuid: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      media: List<Map<String, dynamic>>.from(map['media'] ?? []),
      likes: List<dynamic>.from(map['likes'] ?? []),
      reposts: List<dynamic>.from(map['reposts'] ?? []),
      mentions: List<dynamic>.from(map['mentions'] ?? []),
      richText: parsedRichText,
      event: map['event'] != null
          ? EventModel.fromMap(Map<String, dynamic>.from(map['event']))
          : null,
    );
  }

  /// For Firestore snapshots
  factory PostModal.fromFirestore(Map<String, dynamic> data) {
    List<Map<String, dynamic>> parsedRichText = [];

    if (data['richText'] != null) {
      if (data['richText'] is String) {
        parsedRichText = List<Map<String, dynamic>>.from(
          jsonDecode(data['richText']),
        );
      } else if (data['richText'] is List) {
        parsedRichText = List<Map<String, dynamic>>.from(data['richText']);
      }
    }

    return PostModal(
      uuid: data['postId'] ?? '',
      postIn: data['postIn'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      media: List<Map<String, dynamic>>.from(data['media'] ?? []),
      likes: List<dynamic>.from(data['likes'] ?? []),
      reposts: List<dynamic>.from(data['reposts'] ?? []),
      mentions: List<dynamic>.from(data['mentions'] ?? []),
      richText: parsedRichText,
      event: data['event'] != null
          ? EventModel.fromMap(Map<String, dynamic>.from(data['event']))
          : null,
    );
  }
}
