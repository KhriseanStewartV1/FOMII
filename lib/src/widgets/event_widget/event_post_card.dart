import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/posts/post_services.dart';
import 'package:fomo_connect/src/database/others/calender_service.dart';
import 'package:fomo_connect/src/modal/event_model.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EventPostCard extends StatefulWidget {
  final PostModal? post;
  final EventModel event;

  const EventPostCard({super.key, required this.event, this.post});

  @override
  State<EventPostCard> createState() => _EventPostCardState();
}

class _EventPostCardState extends State<EventPostCard> {
  final uid = AuthService().user!.uid;
  bool pplCheck = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    goingPplCheck();
  }

  String formatDateTimeString(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final formatter = DateFormat('MMMM d, yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  goingPplCheck() async {
    if (widget.post == null) return;

    final doc = await PostServices().getPosts(widget.post!.uuid);
    final going = doc['event'] as Map<String, dynamic>;
    final goingSum = going['going'] as List<dynamic>;

    pplCheck = goingSum.contains(uid);
  }

  Future<void> goingPpl() async {
    try {
      if (widget.post == null) {
        return;
      } else {
        await PostServices().updatePost({
          "going": FieldValue.arrayUnion([uid]),
        }, widget.post!.uuid);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime.parse(widget.event.dateTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              "assets/eventPic.jpeg",
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  widget.event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Date & Location
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDateTimeString(widget.event.dateTime),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "${widget.event.location}, ${widget.event.city}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Going count
                Text(
                  "${widget.event.going?.length ?? 0} going",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MaterialButton(
                        color: pplCheck ? Colors.grey : Colors.lightBlue,
                        onPressed: () => pplCheck ? {} : goingPpl(),
                        child: Text(
                          "Going",
                          style: GoogleFonts.poppins(
                            color: pplCheck ? Colors.black : Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MaterialButton(
                        onPressed: () {
                          if (widget.post == null) {
                            return;
                          } else {
                            addCalendarEvent(
                              title: widget.event.title,
                              date: date,
                            );
                          }
                        },
                        child: const Text("Interested"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MaterialButton(
                        onPressed: () {
                          try {

                          saveEvent(uid, widget.event);
                          } catch (e) {
                            print("Error saving event: $e");
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
