// Stub pour le web — remplace flutter_local_notifications
class FlutterLocalNotificationsPlugin {
  Future<bool?> initialize(dynamic settings) async => true;
  Future<void> show(int id, String? title, String? body, dynamic details) async {}
}
class InitializationSettings { const InitializationSettings({dynamic android}); }
class AndroidInitializationSettings { const AndroidInitializationSettings(String icon); }
class NotificationDetails { const NotificationDetails({dynamic android}); }
class AndroidNotificationDetails {
  const AndroidNotificationDetails(String id, String name, {dynamic importance, dynamic priority, dynamic icon, bool? enableVibration, bool? playSound});
}
class Importance { static const high = Importance._(); const Importance._(); }
class Priority { static const high = Priority._(); const Priority._(); }
