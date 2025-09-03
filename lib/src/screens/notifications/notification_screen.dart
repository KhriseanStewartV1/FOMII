import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notification",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Center(child: Text("In Development :P"),),
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:fomo_connect/src/database/hive_pref/notifications_s_p.dart';
// import 'package:fomo_connect/src/widgets/loading_screen.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';

// class NotificationScreen extends StatelessWidget {
//   const NotificationScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     String getFormattedDate(Timestamp timestamp) {
//       final dateTime = timestamp.toDate();
//       final formatter = DateFormat('MMM dd, yyyy');
//       return formatter.format(dateTime);
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Notification",
//           style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: FutureBuilder(
//           future: NotificationHive().loadNotifications(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData || snapshot.data == null) {
//               return Center(child: Text("No Notifications"));
//             }
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Center(child: LoadingScreen());
//             }
//             final data = snapshot.data;
//             return ListView.separated(
//               separatorBuilder: (context, index) => SizedBox(height: 10),
//               itemCount: data!.length,
//               itemBuilder: (context, index) {
//                 final noti = data[index];
//                 return ListTile(
//                   title: Text(noti.title),
//                   trailing: Text(
//                     getFormattedDate(
//                       Timestamp.fromDate(DateTime.parse(noti.dateTime!)),
//                     ),
//                   ),
//                   leading: Icon(Icons.person),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
