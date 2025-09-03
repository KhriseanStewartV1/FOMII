import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
}
