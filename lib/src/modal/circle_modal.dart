class CircleModel {
  final String circleId;
  final String name;
  final String description;
  final String ownerId;
  final List<String> memberIds;
  final List<String> pendingRequestIds;
  final DateTime createdAt;

  CircleModel({
    required this.circleId,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.memberIds,
    required this.pendingRequestIds,
    required this.createdAt,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'circleId': circleId,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'pendingRequestIds': pendingRequestIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory CircleModel.fromJson(Map<String, dynamic> json) {
    return CircleModel(
      circleId: json['circleId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      pendingRequestIds: List<String>.from(json['pendingRequestIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Copy with method for updates
  CircleModel copyWith({
    String? circleId,
    String? name,
    String? description,
    String? ownerId,
    List<String>? memberIds,
    List<String>? pendingRequestIds,
    DateTime? createdAt,
  }) {
    return CircleModel(
      circleId: circleId ?? this.circleId,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      pendingRequestIds: pendingRequestIds ?? this.pendingRequestIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}