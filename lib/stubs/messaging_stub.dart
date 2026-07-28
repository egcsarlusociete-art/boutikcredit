// Stub Firebase Messaging pour le web
class RemoteMessage {
  final RemoteNotification? notification;
  const RemoteMessage({this.notification});
}
class RemoteNotification {
  final String? title;
  final String? body;
  const RemoteNotification({this.title, this.body});
}
class FirebaseMessaging {
  static Future<void> onBackgroundMessage(Future<void> Function(RemoteMessage) handler) async {}
  static Stream<RemoteMessage> get onMessage => const Stream.empty();
  static FirebaseMessaging get instance => FirebaseMessaging._();
  FirebaseMessaging._();
  Future<void> requestPermission({bool? alert, bool? badge, bool? sound}) async {}
  Future<String?> getToken() async => null;
  Stream<String> get onTokenRefresh => const Stream.empty();
}
