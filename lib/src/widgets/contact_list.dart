import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/database/firebase/chat/chat_service.dart';
import 'package:fomo_connect/src/database/firebase/users/user_services.dart';
import 'package:fomo_connect/src/database/telephone/telephone_service.dart';
import 'package:fomo_connect/src/screens/auth/telephone_screen/telephone_screen.dart';
import 'package:fomo_connect/src/screens/inbox_screen/chat_screen.dart';
import 'package:fomo_connect/src/widgets/contact_photo.dart';
import 'package:fomo_connect/src/screens/loading_splash.dart/loading_screen.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactList extends StatefulWidget {
  const ContactList({super.key});

  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  String uid = AuthService().user!.uid;
  bool contactReq = false;

  @override
  void initState() {
    super.initState();
    getPerms();
    numberCheck(context);
  }

  getPerms() async {
    final perm = await Permission.contacts.request();
    if (perm.isGranted) {
      setState(() {
        contactReq = perm.isGranted;
      });
      return;
    } else {
      await Permission.contacts.request();
    }
  }

  void numberCheck(BuildContext context) async {
    print(contactReq);
    if (contactReq == true) {
      final userDoc = await UserServices().readUser(uid);

      if (userDoc != null && userDoc.exists) {
        try {
          final data = userDoc.data();

          if (data == null ||
              !data.containsKey('telephone') ||
              (data['telephone'] as String).isEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TelephoneScreen()),
            );
          } else {
            return;
          }
        } catch (e) {
          print("Error checking telephone: $e");
        }
      }
    }
  }

  Future<List<Contact>> loadRegisteredContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      return await getRegisteredContacts(contacts);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: contactReq
          ? FutureBuilder<List<Contact>>(
              future: loadRegisteredContacts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: LoadingScreen());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final contacts = snapshot.data ?? [];
                if (contacts.isEmpty) {
                  return const Center(
                    child: Text("No friends found in your contacts."),
                  );
                }
                return ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];

                    return GestureDetector(
                      onTap: () async {
                        final uid = AuthService().user!.uid;
                        final userDoc = await UserServices().getUserData(
                          contact,
                        );
                        if (userDoc == null) {
                          displayRoundedSnackBar(
                            context,
                            "User is not on FOMII",
                          );
                          return;
                        }

                        final otherUserId = userDoc['userId'] as String;

                        final chatId = await ChatService().getOrCreateChat(
                          uid,
                          otherUserId,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserChat(
                              userId: uid,
                              chatId: chatId.id,
                              recieverId: otherUserId,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: ContactPhotoWidget(photoData: contact.photo),
                        title: Text(contact.displayName),
                      ),
                    );
                  },
                );
              },
            )
          : Center(child: Text("Contact Us Request Denied")),
    );
  }
}
