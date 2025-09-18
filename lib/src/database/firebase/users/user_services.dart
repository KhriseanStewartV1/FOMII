import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:fomo_connect/src/database/telephone/telephone_service.dart';
import 'package:fomo_connect/src/modal/user_modal.dart';

final _instance = FirebaseFirestore.instance;

class UserServices {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _db = _instance.collection("users");

  Stream<QuerySnapshot<Map<String, dynamic>>> getUIdSearch(String uIdSearch) {
    return _db.where("uniqueId", isEqualTo: uIdSearch).snapshots();
  }

  Future<bool> createUser(UserModal user) async {
    try {
      await _db.doc(uid).set(user.toMap());
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updateUser(Map<String, dynamic> fieldsToUpdate) async {
    try {
      await _db.doc(uid).update(fieldsToUpdate);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<DocumentSnapshot?> readUser(String userId) async {
    try {
      final doc = await _instance.collection("users").doc(userId).get();
      return doc;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _db.doc(uid).snapshots();
  }

  Future<List<String>> getFollowing(String userId) async {
    try {
      final doc = await _db.doc(uid).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();

      if (data == null || !data.containsKey('followers')) {
        return [];
      }

      // Ensure it's a List<String>
      return List<String>.from(data['followers']);
    } catch (e) {
      print("Error in getFollowing($userId): $e");
      return [];
    }
  }

  Future<String> followingSystem(String userId, bool isFollowing) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        List followers = userDoc.data()?['followers'] ?? [];

        // Check if currentUserId already follows userId
        if (followers.contains(uid) && isFollowing) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
                'followers': FieldValue.arrayRemove([uid]),
              });
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'following': FieldValue.arrayRemove([userId]),
          });
          return "Unfollowed ${userDoc['name']}";
        } else {
          // Proceed to follow
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
                'followers': FieldValue.arrayUnion([uid]),
              });
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'following': FieldValue.arrayUnion([userId]),
          });
          return "Following ${userDoc['name']}";
        }
      } else {
        print('User document does not exist');
        return "User Doesn't seem to exist";
      }
    } catch (e) {
      print(e);
      return 'Error $e';
    }
  }

  Future<bool> isFollowing(String userId, String targetUserId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        List<dynamic> followingList = userDoc.data()?['following'] ?? [];
        return followingList.contains(targetUserId);
      } else {
        print('Current user document does not exist');
        return false;
      }
    } catch (e) {
      print('Error checking following status: $e');
      return false;
    }
  }

  Future<String?> getCount(String userId, String countType) async {
    try {
      final doc = await _db.doc(userId).get();
      // ignore: unnecessary_null_comparison
      if (!doc.exists || doc == null) {
        return null;
      } else {
        final count = doc['$countType'];
        return "${count.length}";
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<String> generateUniqueId(
    String username,
    Future<bool> Function(String) exists,
  ) async {
    String slug = username
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    String candidate = slug;
    int suffix = 1;
    // Loop until a unique ID is found
    while (await exists(candidate)) {
      candidate = '$slug-$suffix';
      suffix++;
    }
    return candidate;
  }

  Future<Map<String, dynamic>?> getUserData(Contact contact) async {
    try {
      // Always format number before query
      final rawNumber = contact.phones.isNotEmpty
          ? contact.phones[0].number
          : null;
      if (rawNumber == null) return null;

      final formatted = formatNumber(rawNumber); // use your formatter
      if (formatted == null) return null;

      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("telephone", isEqualTo: formatted)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final userData = snap.docs.first.data();
        return userData;
        // 👉 Here you can navigate to a profile screen or start a chat
      } else {
        print("No user with number $formatted");
        return null;
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}

Future<bool> checkUniqueIdExists(String uniqueId) async {
  // Query your Firestore collection to see if a document with this uniqueId exists
  final result = await FirebaseFirestore.instance
      .collection('users')
      .where('uniqueId', isEqualTo: uniqueId)
      .get();

  return result.docs.isNotEmpty;
}
