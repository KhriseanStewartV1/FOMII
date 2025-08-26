import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/widgets/misc.dart';

class PostProvider with ChangeNotifier {
  Map<String, PostModal> posts = {};

  // Call this once during app initialization
  void listenToPostUpdates() {
    FirebaseFirestore.instance.collection('posts').snapshots().listen((
      snapshot,
    ) {
      for (var doc in snapshot.docs) {
        final postId = doc.id;
        final data = doc.data();
        final post = PostModal.fromMap(data);
        posts[postId] = post; // update local cache
      }
      notifyListeners(); // rebuild UI with latest data
    });
  }

  void setPosts(List<PostModal> newPosts) {
    posts = {for (var post in newPosts) post.uuid: post};
    notifyListeners();
  }

  // Your toggle methods can stay as is, but consider updating Firestore directly
  void toggleLike(String postId, String uid, BuildContext context) async {
    final post = posts[postId];
    if (post == null) return;

    // Optimistic UI update
    if (post.likes.contains(uid)) {
      post.likes.remove(uid);
    } else {
      post.likes.add(uid);
    }
    notifyListeners();

    // Firestore update
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    try {
      await postRef.update({'likes': post.likes});
    } catch (e) {
      print(e);
      displayRoundedSnackBar(context, "Post Doesn't Exist");
    }
  }

  void toggleRepost(String postId, String uid, BuildContext context) async {
    final post = posts[postId];
    if (post == null) return;
    try {
      if (post.reposts.contains(uid)) {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
          {
            'reposts': FieldValue.arrayRemove([uid]),
          },
        );
      } else {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
          {
            'reposts': FieldValue.arrayUnion([uid]),
          },
        );
      }
    } catch (e) {
      displayRoundedSnackBar(context, "Post Doesn't Exist");
    }
  }
}
