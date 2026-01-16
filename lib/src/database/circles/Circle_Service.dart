import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fomo_connect/src/modal/circle_modal.dart';

class CircleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  // Create a new circle
  Future<void> createCircle({
    required String name,
    required String description,
  }) async {
    try {
      // Check if user already owns 3 circles
      final userCircles = await _firestore
          .collection('circles')
          .where('ownerId', isEqualTo: currentUserId)
          .get();

      if (userCircles.docs.length >= 3) {
        throw Exception('You can only create up to 3 circles');
      }

      // Check total circles user is part of
      final allUserCircles = await _firestore
          .collection('circles')
          .where('memberIds', arrayContains: currentUserId)
          .get();

      if (allUserCircles.docs.length >= 3) {
        throw Exception('You can only be part of 3 circles');
      }

      final circleId = _firestore.collection('circles').doc().id;

      final circle = CircleModel(
        circleId: circleId,
        name: name,
        description: description,
        ownerId: currentUserId,
        memberIds: [currentUserId], // Owner is automatically a member
        pendingRequestIds: [],
        createdAt: DateTime.now(),
      );

      await _firestore.collection('circles').doc(circleId).set(circle.toJson());
    } catch (e) {
      throw Exception('Failed to create circle: $e');
    }
  }

  // Get user's circles (where they are a member)
  Stream<List<CircleModel>> getUserCircles() {
    return _firestore
        .collection('circles')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CircleModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Get circle requests for current user
  Stream<List<CircleModel>> getCircleRequests() {
    return _firestore
        .collection('circles')
        .where('pendingRequestIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CircleModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Invite a user to a circle
  Future<void> inviteToCircle(String circleId, String userId) async {
    try {
      final circleDoc = await _firestore
          .collection('circles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) {
        throw Exception('Circle not found');
      }

      final circle = CircleModel.fromJson(circleDoc.data()!);

      // Check if current user is the owner
      if (circle.ownerId != currentUserId) {
        throw Exception('Only the owner can invite members');
      }

      // Check if circle is full
      if (circle.memberIds.length >= 10) {
        throw Exception('Circle is full (max 10 members)');
      }

      // Check if user is already a member
      if (circle.memberIds.contains(userId)) {
        throw Exception('User is already a member');
      }

      // Check if user already has a pending request
      if (circle.pendingRequestIds.contains(userId)) {
        throw Exception('User already has a pending request');
      }

      // Check if invited user is already in 3 circles
      final userCircles = await _firestore
          .collection('circles')
          .where('memberIds', arrayContains: userId)
          .get();

      if (userCircles.docs.length >= 3) {
        throw Exception('User is already part of 3 circles');
      }

      await _firestore.collection('circles').doc(circleId).update({
        'pendingRequestIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to invite user: $e');
    }
  }

  // Accept circle request
  Future<void> acceptCircleRequest(String circleId) async {
    try {
      final circleDoc = await _firestore
          .collection('circles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) {
        throw Exception('Circle not found');
      }

      final circle = CircleModel.fromJson(circleDoc.data()!);

      // Check if circle is full
      if (circle.memberIds.length >= 10) {
        throw Exception('Circle is full');
      }

      // Check if user is already in 3 circles
      final userCircles = await _firestore
          .collection('circles')
          .where('memberIds', arrayContains: currentUserId)
          .get();

      if (userCircles.docs.length >= 3) {
        throw Exception('You are already part of 3 circles');
      }

      await _firestore.collection('circles').doc(circleId).update({
        'memberIds': FieldValue.arrayUnion([currentUserId]),
        'pendingRequestIds': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  // Decline circle request
  Future<void> declineCircleRequest(String circleId) async {
    try {
      await _firestore.collection('circles').doc(circleId).update({
        'pendingRequestIds': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      throw Exception('Failed to decline request: $e');
    }
  }

  // Leave a circle
  Future<void> leaveCircle(String circleId) async {
    try {
      final circleDoc = await _firestore
          .collection('circles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) {
        throw Exception('Circle not found');
      }

      final circle = CircleModel.fromJson(circleDoc.data()!);

      // Owner cannot leave their own circle
      if (circle.ownerId == currentUserId) {
        throw Exception('Owner cannot leave circle. Delete it instead.');
      }

      await _firestore.collection('circles').doc(circleId).update({
        'memberIds': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      throw Exception('Failed to leave circle: $e');
    }
  }

  // Remove a member (owner only)
  Future<void> removeMember(String circleId, String memberId) async {
    try {
      final circleDoc = await _firestore
          .collection('circles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) {
        throw Exception('Circle not found');
      }

      final circle = CircleModel.fromJson(circleDoc.data()!);

      // Check if current user is the owner
      if (circle.ownerId != currentUserId) {
        throw Exception('Only the owner can remove members');
      }

      // Cannot remove the owner
      if (memberId == circle.ownerId) {
        throw Exception('Cannot remove the owner');
      }

      await _firestore.collection('circles').doc(circleId).update({
        'memberIds': FieldValue.arrayRemove([memberId]),
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Delete a circle (owner only)
  Future<void> deleteCircle(String circleId) async {
    try {
      final circleDoc = await _firestore
          .collection('circles')
          .doc(circleId)
          .get();

      if (!circleDoc.exists) {
        throw Exception('Circle not found');
      }

      final circle = CircleModel.fromJson(circleDoc.data()!);

      // Check if current user is the owner
      if (circle.ownerId != currentUserId) {
        throw Exception('Only the owner can delete the circle');
      }

      await _firestore.collection('circles').doc(circleId).delete();
    } catch (e) {
      throw Exception('Failed to delete circle: $e');
    }
  }

  // Get circles for posts (for the feed filter)
  Future<List<String>> getUserCircleIds() async {
    try {
      final circles = await _firestore
          .collection('circles')
          .where('memberIds', arrayContains: currentUserId)
          .get();

      return circles.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Get specific circle
  Future<CircleModel?> getCircle(String circleId) async {
    try {
      final doc = await _firestore.collection('circles').doc(circleId).get();
      if (doc.exists) {
        return CircleModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
