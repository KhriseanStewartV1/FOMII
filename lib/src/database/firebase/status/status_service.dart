import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/modal/status_model.dart';
import 'package:fomo_connect/src/widgets/misc.dart';

final _status = FirebaseFirestore.instance.collection("status");

class StatusService {
  Future<void> uploadStatus(
    BuildContext context, {
    required StatusModel stat,
    required String uid,
  }) async {
    try {
      _status.doc(uid).set(stat.toMap());
    } on FirebaseException catch (e) {
      displayRoundedSnackBar(context, "Error Uploading Image: ${e.message}");
    }
  }

  Future<void> readStatus(
    BuildContext context,
  ) async {
    try {
      _status.get();
    } on FirebaseException catch (e) {
      displayRoundedSnackBar(context, "Error Uploading Image: ${e.message}");
    }
  }
}
