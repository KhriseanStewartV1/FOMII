import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/status/status_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/others/calender_service.dart';
import 'package:fomo_connect/src/database/others/image.dart';
import 'package:fomo_connect/src/database/storage/image.dart';
import 'package:fomo_connect/src/modal/event_model.dart';
import 'package:fomo_connect/src/modal/status_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class RecentEvents extends StatefulWidget {
  const RecentEvents({super.key});

  @override
  State<RecentEvents> createState() => _RecentEventsState();
}

class _RecentEventsState extends State<RecentEvents> {
  Future<void> statusImg() async {
    try {
      final dir = await Directory.systemTemp.createTemp();
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final compressed = await compressImage(
        toFile(image),
        400,
        400,
        70,
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (compressed == null) return;

      final url = await ImageService().uploadStatus(
        file: toFile(compressed),
        uid: AuthService().user!.uid,
      );
      final userDoc = await UserServices().readUser(AuthService().user!.uid);
      print(userDoc!.data());
      await UserServices().updateUser({'status': url});
      await StatusService().uploadStatus(
        context,
        stat: StatusModel(
          url: url,
          userName: "userName",
          published: DateTime.now(),
        ),
        uid: AuthService().user!.uid,
      );
    } catch (e) {
      debugPrint("❌ Error picking/uploading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatDateTimeString(String dateString) {
      try {
        final dateTime = DateTime.parse(dateString);
        final now = DateTime.now();
        final difference = dateTime.difference(now);

        if (difference.inDays == 0) {
          return 'Today';
        } else if (difference.inDays == 1) {
          return 'Tomorrow';
        } else if (difference.inDays < 7) {
          return DateFormat('EEEE').format(dateTime);
        } else {
          return DateFormat('MMM d').format(dateTime);
        }
      } catch (e) {
        return dateString;
      }
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder(
        stream: loadEvent(AuthService().user?.uid ?? ''),
        builder: (context, async) {
          if (async.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }

          if (async.hasError) {
            return _buildErrorState();
          }

          if (!async.hasData || async.data == null || async.data!.isEmpty) {
            return _buildEmptyState();
          }

          final events = async.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length, // +1 for add event button
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event, formatDateTimeString);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event, String Function(String) formatDate) {
    final bool isUpcoming = _isEventUpcoming(event.dateTime);

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showEventDetails(event),
            onLongPress: () => _showEventOptions(event),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: isUpcoming
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isUpcoming
                        ? const Color(0xFFFF6B6B).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(child: Icon(Icons.calendar_today)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            formatDate(event.dateTime),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: isUpcoming ? const Color(0xFFFF6B6B) : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 35,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Failed to load events',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No upcoming events',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  bool _isEventUpcoming(String? dateTimeString) {
    if (dateTimeString == null) return false;
    try {
      final eventDate = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      return eventDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                event.title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatFullDateTime(event.dateTime),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Join Event',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => addGoing(event),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF667EEA),
                        side: const BorderSide(color: Color(0xFF667EEA)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Going',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addGoing(EventModel event) {
    try {
      event.going!.add(uid);
    } catch (e) {
      print(e);
    }
  }

  void _showEventOptions(dynamic event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(context);
                // Add edit functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Event'),
              onTap: () {
                Navigator.pop(context);
                // Add share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.highlight_remove, color: Colors.red),
              title: const Text(
                'Remove from Pinned',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add unpin functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDateTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('EEEE, MMMM d, yyyy \'at\' h:mm a').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }
}
