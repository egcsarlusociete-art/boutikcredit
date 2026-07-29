import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart' if (dart.library.html) 'stubs/messaging_stub.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' if (dart.library.html) 'stubs/notifications_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'utils/theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // FCM — desactive sur web
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: androidSettings));
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          final db = FirebaseFirestore.instance;
          final uSnap = await db.collection('users').doc(user.uid).get();
          final coll = uSnap.exists ? 'users' : 'vendeurs';
          await db.collection(coll).doc(user.uid).update({'fcmToken': token}).catchError((_) {});
        }
      });
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final db = FirebaseFirestore.instance;
        final uSnap = await db.collection('users').doc(user.uid).get();
        final coll = uSnap.exists ? 'users' : 'vendeurs';
        await db.collection(coll).doc(user.uid).update({'fcmToken': newToken}).catchError((_) {});
      }
    });
  }
  
  // Notifications foreground — desactive sur web
  if (!kIsWeb) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails('boutikcredit_channel', 'BoutikCredit',
              importance: Importance.high, priority: Priority.high, icon: '@mipmap/ic_launcher', enableVibration: true, playSound: true),
          ),
        );
      }
    });
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
// Note: utilise uniquement sur Android/iOS via kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // FCM — desactive sur web
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: androidSettings));
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          final db = FirebaseFirestore.instance;
          final uSnap = await db.collection('users').doc(user.uid).get();
          final coll = uSnap.exists ? 'users' : 'vendeurs';
          await db.collection(coll).doc(user.uid).update({'fcmToken': token}).catchError((_) {});
        }
      });
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final db = FirebaseFirestore.instance;
        final uSnap = await db.collection('users').doc(user.uid).get();
        final coll = uSnap.exists ? 'users' : 'vendeurs';
        await db.collection(coll).doc(user.uid).update({'fcmToken': newToken}).catchError((_) {});
      }
    });
  }
  
  // Notifications foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails('boutikcredit_channel', 'BoutikCredit',
            importance: Importance.high, priority: Priority.high, icon: '@mipmap/ic_launcher', enableVibration: true, playSound: true),
        ),
      );
    }
  });
  await initializeDateFormatting('fr_FR', null);
  runApp(const ProviderScope(child: EgcApp()));
}

class EgcApp extends ConsumerWidget {
  const EgcApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'EGC-SARLU',
      theme: EgcTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: kIsWeb
          ? Container(
              color: const Color(0xFF0F1117),
              child: Center(
                child: SizedBox(
                  width: 430,
                  height: MediaQuery.of(context).size.height,
                  child: child!,
                ),
              ),
            )
          : child!,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EgcColors.primary,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/images/logo_boutikcredit.png', height: 100),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ])),
    );
  }
}
