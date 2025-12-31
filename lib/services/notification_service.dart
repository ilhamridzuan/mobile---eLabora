import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//  tambah
import '../data/notification_store.dart';

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'antrian',
  'Notifikasi Antrian',
  description: 'Notifikasi saat antrian dipanggil',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Untuk saat ini biarkan kosong.
  // Android biasanya menampilkan notif otomatis jika payload berisi "notification".
  // Jika nanti Anda ingin menyimpan notifikasi dari background/data-only,
  // kita bisa upgrade di sini (butuh Firebase.initializeApp di background isolate).
}

class NotificationService {
  static Future<void> init() async {
    // Local notification init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotif.initialize(initSettings);

    // Create channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // FCM permission
    final fm = FirebaseMessaging.instance;
    await fm.requestPermission(alert: true, badge: true, sound: true);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground handler -> simpan + tampilkan via local notif
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notif = message.notification;
      final title = notif?.title ?? 'Notifikasi';
      final body = notif?.body ?? '';

      //  simpan ke inbox lokal
      await NotificationStore.add(
        AppNotification(
          id: message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          data: message.data,
          receivedAt: DateTime.now(),
          read: false,
        ),
      );

      await showLocal(title: title, body: body, payload: message.data);
    });
  }

  static Future<void> showLocal({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload == null ? null : jsonEncode(payload),
    );
  }
}
