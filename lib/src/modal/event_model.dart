class EventModel {
  final String title;
  final String dateTime;
  final String location;
  final String city;
  final List<String>? going;

  const EventModel({
    required this.title,
    required this.dateTime,
    required this.location,
    required this.city,
    this.going = const [],
  });

  /// Convert EventModel to Map (for Firestore/JSON)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dateTime': dateTime,
      'location': location,
      'city': city,
      'going': going
    };
  }

  /// Create EventModel from Map (from Firestore/JSON)
  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      title: map['title'] ?? '',
      dateTime: map['dateTime'] ?? '',
      location: map['location'] ?? '',
      city: map['city'] ?? '',
      going: List<String>.from(map['going'] ?? []),
    );
  }
}
