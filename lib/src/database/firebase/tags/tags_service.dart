import 'package:firebase_database/firebase_database.dart';

class TagService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<List<String>> getTags() async {
    try {
      final snapshot = await _db.child("tags").get();

      if (snapshot.exists) {
        // snapshot.value is dynamic → cast to List or Map
        final data = snapshot.value;

        if (data is List) {
          // If tags are stored as a Firebase list
          return data.whereType<String>().toList();
        } else if (data is Map) {
          // If tags are stored as a Firebase map
          return data.values.map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print("Error fetching tags: $e");
      return [];
    }
  }

  /// Add a tag only if it doesn't already exist
  Future<void> addTag(String tag) async {
    try {
      final snapshot = await _db.child("tags").get();

      List<String> currentTags = [];

      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is List) {
          currentTags = data.whereType<String>().toList();
        } else if (data is Map) {
          currentTags = data.values.map((e) => e.toString()).toList();
        }
      }

      if (currentTags.contains(tag)) {
        print("Tag already exists: $tag");
        return;
      }

      // Add new tag
      await _db.child("tags").push().set(tag);
      print("Tag added: $tag");
    } catch (e) {
      print("Error adding tag: $e");
    }
  }

}
