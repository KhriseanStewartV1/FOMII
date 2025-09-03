import 'dart:typed_data';

import 'package:flutter_contacts/flutter_contacts.dart';

enum PhoneLabel { mobile, work, home, other }
enum EmailLabel { personal, work, other }
enum AddressLabel { home, work, other }
enum WebsiteLabel { personal, work, other }
enum SocialMediaLabel { twitter, facebook, linkedin, instagram, other }
enum EventLabel { birthday, anniversary, other }

class Contact {
  String id;
  String displayName;
  Uint8List? photo;
  Uint8List? thumbnail;
  Name name;
  List<Phone> phones;
  List<Email> emails;
  List<Address> addresses;
  List<Organization> organizations;
  List<Website> websites;
  List<SocialMedia> socialMedias;
  List<Event> events;
  List<Note> notes;
  List<Group> groups;

  // Constructor
  Contact({
    required this.id,
    required this.displayName,
    this.photo,
    this.thumbnail,
    required this.name,
    this.phones = const [],
    this.emails = const [],
    this.addresses = const [],
    this.organizations = const [],
    this.websites = const [],
    this.socialMedias = const [],
    this.events = const [],
    this.notes = const [],
    this.groups = const [],
  });
}