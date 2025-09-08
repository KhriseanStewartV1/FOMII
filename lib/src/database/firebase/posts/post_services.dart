import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:rxdart/rxdart.dart';

final _instance = FirebaseFirestore.instance;

class PostServices {
  final _db = _instance.collection("posts");
  Future<bool> post(PostModal post, String uuid) async {
    try {
      await _db.doc(uuid).set(post.toMap());
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Stream<List<PostModal>> readPosts() {
    return _db.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModal.fromMap(doc.data()))
          .toList();
      posts.shuffle(); // 🔀 shuffle the list
      return posts;
    });
  }

  Stream<List<PostModal>> readLatestPosts() {
    return _db.orderBy('timestamp', descending: true).limit(1).snapshots().map((
      snapshot,
    ) {
      final posts = snapshot.docs
          .map((doc) => PostModal.fromMap(doc.data()))
          .toList();
      return posts;
    });
  }

  // Function to load more posts (older than current last)
  Future<List<PostModal>> fetchMorePosts(DocumentSnapshot lastDocument) async {
    final query = _db
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDocument)
        .limit(10);

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      lastDocument = snapshot.docs.last;
    }
    return snapshot.docs.map((doc) => PostModal.fromMap(doc.data())).toList();
  }

  Future<void> addComment(
    String comment,
    String uid,
    String profilePic,
    DateTime timestamp,
    String name,
    String postId,
  ) async {
    try {
      await _db.doc(postId).collection("comments").add({
        'comment': comment,
        'uid': uid,
        'profilePic': profilePic,
        'timestamp': timestamp,
        'name': name,
      });
    } catch (e) {
      print(e);
    }
  }
  
  Stream<QuerySnapshot<Map<String, dynamic>>> numberOfComments (String postId) {
    return _db.doc(postId).collection("comments").snapshots();
  }

  Stream<List<Map<String, dynamic>>> readComments(String postId) {
    return _db
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<PostModal>> readYourPosts(String uid) {
    return _db
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModal.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<DocumentSnapshot?> getProfile(String userId) async {
    try {
      final doc = await _instance.collection("users").doc(userId).get();
      return doc;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Stream<List<PostModal>> getFollowingPosts(String userId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .snapshots()
        .asyncExpand((userDoc) {
          if (!userDoc.exists) return Stream.value([]);

          final data = userDoc.data();
          final following = List<String>.from(data?['following'] ?? []);

          if (following.isEmpty) return Stream.value([]);

          // Split into chunks of 10
          final chunks = <List<String>>[];
          for (var i = 0; i < following.length; i += 10) {
            chunks.add(
              following.sublist(
                i,
                i + 10 > following.length ? following.length : i + 10,
              ),
            );
          }

          // Merge multiple Firestore queries into one stream
          final streams = chunks.map((chunk) {
            return _db
                .where('userId', whereIn: chunk)
                .orderBy('timestamp', descending: true)
                .snapshots()
                .map(
                  (snap) => snap.docs.map((doc) {
                    final map = doc.data();
                    return PostModal.fromMap(map);
                  }).toList(),
                );
          });

          return Rx.combineLatest<List<PostModal>, List<PostModal>>(
            streams,
            (lists) => lists.expand((list) => list).toList()
              ..sort(
                (a, b) => b.timestamp.compareTo(a.timestamp),
              ), // merge sort
          );
        });
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _db.doc(postId).delete();
      return true;
    } catch (e) {
      print("Error deleting post: $e");
      return false;
    }
  }
}
