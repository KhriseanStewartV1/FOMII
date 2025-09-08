import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/modal/forum_modal.dart';
import 'package:fomo_connect/src/widgets/misc.dart';

final dbRef = FirebaseDatabase.instance.ref();

class ForumService {
  Future<void> addForumPost(BuildContext context, ForumModal forum) async {
    try{
      await dbRef.child("forums").child(forum.autherId).set(forum.toMap());
    }catch(e){
      print(e);
      displayRoundedSnackBar(context, "Error creating Forum: $e");
    }
  }

  Future<bool> addLike(BuildContext context, ForumModal forum, String userId) async {
    try {
      final postRef = dbRef.child("forums").child(forum.autherId); // use post UUID
      final snapshot = await postRef.child("likes").get();

      List<dynamic> likes = [];
      if (snapshot.exists && snapshot.value != null) {
        likes = List<dynamic>.from(snapshot.value as List);
      }

      if (likes.contains(userId)) {
        // Already liked
        displayRoundedSnackBar(context, "You already liked this post");
        return false;
      }

      // Add new like {
        likes.add(userId); // like

      await postRef.update({'likes': likes});

      await postRef.update({'likes': likes});

      return true;
    } catch (e) {
      print(e);
      displayRoundedSnackBar(context, "Error liking post: $e");
      return false;
    }
  }

  Future<bool> removeLike(BuildContext context, ForumModal forum, String userId) async {
    try {
      final postRef = dbRef.child("forums").child(forum.autherId); // use post UUID
      final snapshot = await postRef.child("dislikes").get();

      List<dynamic> dislikes = [];
      if (snapshot.exists && snapshot.value != null) {
        dislikes = List<dynamic>.from(snapshot.value as List);
      }

      if (dislikes.contains(userId)) {
        displayRoundedSnackBar(context, "You already disliked this post");
        return false;
      }

      dislikes.add(userId); // unlike

      await postRef.update({'dislikes': dislikes});

      return true;
    } catch (e) {
      print(e);
      displayRoundedSnackBar(context, "Error liking post: $e");
      return false;
    }
  }

  Future<ForumModal?> getForumPost(String autherId) async {
    try {
      final snapshot = await dbRef.child("forums").child(autherId).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return ForumModal.fromMap(data);
      }
    } catch (e) {
      print("Error getting forum post: $e");
    }
    return null;
  }

  Stream<List<ForumModal>> streamPosts() {
    final ref = dbRef.child("forums");

    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data != null) {
        final map = Map<String, dynamic>.from(data as Map);
        // Convert each child to ForumModal
        return map.entries.map((e) {
          final postMap = Map<String, dynamic>.from(e.value as Map);
          return ForumModal.fromMap(postMap);
        }).toList();
      }
      return <ForumModal>[];
    });
  }
}
