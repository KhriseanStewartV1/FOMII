class NotificationModel {
  String id; // Unique ID for the notification
  String title;
  String body;
  String receiverUid; // Corrected spelling
  DateTime dateTime; // Use DateTime for easier sorting & comparison
  bool isRead;
  String? senderUid; // Who sent the notification
  String? type; // Optional: e.g., 'attendance', 'announcement', 'message'
  String? payload; // Optional JSON or extra info for deep linking
  String? imageUrl; // Optional image for rich notifications
  bool isPinned; // Optional: if notification is important and should stay on top

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.dateTime,
    required this.isRead,
    required this.receiverUid,
    this.senderUid,
    this.type,
    this.payload,
    this.imageUrl,
    this.isPinned = false,
  });

  // Convert to map for Firestore / JSON
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'receiverUid': receiverUid,
        'senderUid': senderUid,
        'dateTime': dateTime.toIso8601String(),
        'isRead': isRead,
        'type': type,
        'payload': payload,
        'imageUrl': imageUrl,
        'isPinned': isPinned,
      };

  // Construct from Firestore / JSON
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '', // fallback to empty string
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      receiverUid: map['receiverUid'],
      senderUid: map['senderUid'],
      dateTime: map['dateTime'] != null
          ? DateTime.parse(map['dateTime'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'],
      payload: map['payload'],
      imageUrl: map['imageUrl'],
      isPinned: map['isPinned'] ?? false,
    );
  }
}
