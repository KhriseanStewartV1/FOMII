import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';


String? formatNumber(String rawNumber, {String regionCode = "US"}) {
  try {
    final phoneNumber = PhoneNumber.parse(rawNumber, callerCountry: IsoCode.US);

    // Build strict E.164 format
    return "+${phoneNumber.countryCode}${phoneNumber.nsn}";
  } catch (e) {
    print("Error parsing number: $e");
    return null;
  }
}

Future<List<Contact>> getRegisteredContacts(List<Contact> deviceContacts) async {
  List<Contact> registered = [];

  // Loop through contacts
  for (final contact in deviceContacts) {
    for (final phone in contact.phones) {
      final formatted = formatNumber(phone.number);
      if (formatted == null) continue;

      // Query Firestore for this number
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .where('telephone', isEqualTo: formatted)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        registered.add(contact);
        break; // no need to check other numbers of this contact
      }
    }
  }

  return registered;
}