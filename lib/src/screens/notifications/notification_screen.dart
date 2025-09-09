import 'package:flutter/material.dart';
import 'package:fomo_connect/src/modal/notifications_model.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:intl/intl.dart';

import 'package:fomo_connect/src/database/firebase/notifications/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String _formatDate(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'attendance':
        return FeatherIcons.clock;
      case 'message':
        return FeatherIcons.mail;
      case 'alert':
        return FeatherIcons.alertCircle;
      default:
        return FeatherIcons.bell;
    }
  }

  Color _getBackground(bool isRead) {
    return isRead ? Colors.white : Colors.blue.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.checkCircle),
            tooltip: "Mark all as read",
            onPressed: () {
              NotificationService().markAllAsRead();
              displayRoundedSnackBar(context, "Notifications marked as Read");
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService().streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No Notifications",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final noti = notifications[index];
          
              return Dismissible(
                key: Key(noti.id),
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await NotificationService().deleteNotification(noti.id);
                },
                child: Container(
                  color: _getBackground(noti.isRead),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: noti.isRead ? Colors.grey[300] : Colors.blue,
                      child: Icon(
                        _getIcon(noti.type),
                        color: noti.isRead ? Colors.grey[600] : Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      noti.title,
                      style: GoogleFonts.poppins(
                        fontWeight: noti.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: noti.body.isNotEmpty
                        ? Text(
                            noti.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          )
                        : null,
                    trailing: Text(
                      noti.dateTime != null ? _formatDate(noti.dateTime.toString()) : '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    onTap: () async {
                      if (!noti.isRead) {
                        await NotificationService().markAsRead(noti.id);
                      }
                      // Optional: navigate to detail or relevant page
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
