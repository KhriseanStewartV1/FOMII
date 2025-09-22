class UserModal {
  final String userId;
  final String name;
  final String? profilePic;
  final DateTime createdAt;
  final String? bio;
  final String? email;
  final int? followersCount;
  final int? followingCount;
  final bool? isVerified;
  final List<String>? followers; // List of user IDs
  final List<String>? following; // List of user IDs
  final String? uniqueId;
  final bool? terms;

  UserModal({
    required this.userId,
    required this.name,
    this.profilePic,
    required this.createdAt,
    this.bio,
    this.email,
    this.followersCount,
    this.followingCount,
    this.isVerified,
    this.followers,
    this.following,
    this.uniqueId,
    this.terms
  });

  // Convert to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'profilePic': profilePic,
      'createdAt': createdAt.toIso8601String(),
      'terms' : terms,
      if (bio != null) 'bio': bio,
      if (email != null) 'email': email,
      if (followersCount != null) 'followersCount': followersCount,
      if (followingCount != null) 'followingCount': followingCount,
      if (isVerified != null) 'isVerified': isVerified,
      'followers': followers ?? [],
      'following': following ?? [],
      if (uniqueId != null) 'uniqueId': uniqueId,
    };
  }

  // Create an instance from Map
  factory UserModal.fromMap(Map<String, dynamic> map) {
    return UserModal(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      profilePic: map['profilePic'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      bio: map['bio'],
      email: map['email'],
      followersCount: map['followersCount'],
      followingCount: map['followingCount'],
      isVerified: map['isVerified'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      uniqueId: map['uniqueId'],
      terms: map['terms']
    );
  }
}
