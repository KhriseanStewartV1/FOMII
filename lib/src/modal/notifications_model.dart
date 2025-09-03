class NotificationModel {
  String title;
  String body;
  String? recieverUid;
  String? dateTime;

  NotificationModel({
    required this.title,
    required this.body,
    this.recieverUid,
    this.dateTime,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'recieverUid': recieverUid,
    'dateTime': dateTime,
  };
  NotificationModel.fromMap(Map<String, dynamic> map)
    : title = map['title'],
      body = map['body'],
      recieverUid = map['receiverUid'],
      dateTime = map['dateTime'];
}
