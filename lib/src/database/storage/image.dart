import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Future<String?> uploadImage({required File file, required String uid}) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('posts/$uid/$fileName');

      //Upload File
      final UploadTask = await ref.putFile(file);

      //Get download URL
      final downloadUrl = await UploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Upload failed: $e");
      return null;
    }
  }

  Future<String> uploadProfile({
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
    } catch (e) {
      print("Upload failed: $e");
      return '';
    }
  }

  Future<String> uploadStatus({
    required File file,
    required String uid,
  }) async {
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
