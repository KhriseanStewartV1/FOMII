class PostModal {
  final String userId; // ID of the user who created the post
  final String userName; // Name of the user
  final String postText; // The content of the post
  final List<String> tags; // List of tags associated with the post
  final DateTime timestamp; // When the post was created
  final String? imageUrl; // Optional media URL (photo/video)
  final String uuid;
  List<dynamic> likes; // list of user IDs
  List<dynamic> reposts; // list of user IDs
  List<dynamic> mentions; // list of comment IDs

  PostModal({
    required this.userId,
    required this.userName,
    required this.postText,
    required this.tags,
    required this.timestamp,
    required this.uuid,
    this.imageUrl,
    List<dynamic>? likes,
    List<dynamic>? reposts,
    List<dynamic>? mentions,
  }) : likes = likes ?? [],
       reposts = reposts ?? [], mentions = mentions ?? [];

  // Convert to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'postId': uuid,
      'userId': userId,
      'userName': userName,
      'postText': postText,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
      'mediaUrl': imageUrl,
      'likes': likes,
      'reposts': reposts,
    };
  }

  // Create an instance from Map
  factory PostModal.fromMap(Map<String, dynamic> map) {
    return PostModal(
      uuid: map['postId'] ?? '', // Use 'postId' as per toMap()
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      postText: map['postText'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      timestamp: DateTime.parse(map['timestamp']),
      imageUrl: map['mediaUrl'],
      likes: List<dynamic>.from(map['likes'] ?? []),
      reposts: List<dynamic>.from(map['reposts'] ?? []),
    );
  }
}
