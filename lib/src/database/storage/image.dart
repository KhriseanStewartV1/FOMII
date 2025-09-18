import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/widgets/misc.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Future<String?> uploadImage({required File file, required String uid,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('posts/$uid/$fileName');

      //Upload File
      final UploadTask uploadTask = ref.putFile(file);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

  // Wait for completion
      final TaskSnapshot completedSnapshot = await uploadTask;
      final downloadUrl = await completedSnapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print("Upload failed: $e");
      return null;
    }
  }

Future<String?> uploadVideoWithProgress({
    required File file,
    required String uid,
    void Function(double progress)? onProgress, // 0.0 to 1.0
  }) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('posts/$uid/$fileName');

      final UploadTask uploadTask = ref.putFile(file);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      // Wait for completion
      final TaskSnapshot completedSnapshot = await uploadTask;
      final downloadUrl = await completedSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<String> uploadProfile(
    BuildContext context, {
    required File file,
    required String uid,
  }) async {
    try {
      final fileName = uid;
      final ref = _storage.ref().child('users/$uid/$fileName');

      //Upload File
      final uploadTask = await ref.putFile(file);

      //Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      displayRoundedSnackBar(context, "Upload failed: ${e.message}");
      return '';
    }
  }

  Future<String> uploadStatus({required File file, required String uid}) async {
    try {
      final fileName = uid;
      final ref = _storage.ref().child('users/status/$fileName');

      //Upload File
      final uploadTask = await ref.putFile(file);

      //Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Upload failed: $e");
      return '';
    }
  }
}
