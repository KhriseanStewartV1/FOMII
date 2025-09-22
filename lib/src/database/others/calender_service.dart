import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fomo_connect/src/modal/event_model.dart';

final uid = FirebaseAuth.instance.currentUser!.uid;
final _instance = FirebaseFirestore.instance;
final _db = _instance.collection("users");

void addCalendarEvent({required String title, required DateTime date}) {
  final Event event = Event(
    title: title,
    description: 'Added from app',
    startDate: date,
    endDate: date.add(Duration(hours: 5)),
    allDay: true,
  );

  Add2Calendar.addEvent2Cal(event);
}

Future<void> saveEvent(String uid, EventModel event) async {
  try {
    _db.doc(uid).collection("events").doc().set(event.toMap());
  } catch (e) {
    print(e);
  }
}

Stream<List<EventModel>> loadEvent(String uid) {
  return _db
      .doc(uid)
      .collection("events")
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList(),
      );
}
