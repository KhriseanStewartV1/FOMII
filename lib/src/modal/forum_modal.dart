import 'package:cloud_firestore/cloud_firestore.dart';

class ForumModal {
  String title;
  String name;
  int createdAt;
  List<String>? tags;
  String? profilePic;
  List<String>? likes;
  List<String>? dislikes;
  String uuid;
  String autherId;

  ForumModal({
    required this.title,
    required this.name,
    required this.createdAt,
    this.tags,
    this.profilePic,
    this.likes,
    this.dislikes,
    required this.uuid,
    required this.autherId
  });

  // Convert ForumModal -> Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'name': name,
      'createdAt': createdAt,
      'tags': tags ?? [],
      'profilePic': profilePic,
      'likes': likes ?? [],
      'dislikes': dislikes ?? [],
      'uuid': uuid,
      'autherId': autherId
    };
  }

  // Convert Map -> ForumModal (from Firestore)
  factory ForumModal.fromMap(Map<String, dynamic> map) {
    return ForumModal(
      title: map['title'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      profilePic: map['profilePic'],
      likes: map['likes'] != null ? List<String>.from(map['likes']) : [],
      dislikes: map['dislikes'] != null ? List<String>.from(map['dislikes']) : [],
      uuid: map['uuid'] ?? '',
      autherId: map['autherId'] ?? ''
    );
  }
}
