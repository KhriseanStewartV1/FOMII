import 'package:fomo_connect/src/modal/notifications_model.dart';
import 'package:hive/hive.dart';

class NotificationHive {
  late Box _box;
  static final NotificationHive _instance = NotificationHive._internal();

 factory NotificationHive() {
    return _instance;
  }

  NotificationHive._internal();

  Future<void> init() async {
    _box = await Hive.openBox('notifications');
  }

Future<void> saveNotification(NotificationModel notif) async {
  var box = await Hive.openBox('notifications');
  box.add(notif.toMap());
}

Future<List<NotificationModel>> loadNotifications() async {
  var box = await Hive.openBox('notifications');
  return box.values
      .map((e) => NotificationModel.fromMap(Map<String, dynamic>.from(e)))
      .toList();
}
Future<void> close() async {
    await _box.close();
  }

}