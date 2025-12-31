import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';

class DevicesApi {
  final ApiClient _client;
  DevicesApi(this._client);

  Future<void> registerMyDeviceToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    await _client.dio.post(
      '/devices/token',
      data: {
        'fcm_token': fcmToken,
        'platform': 'ANDROID',
      },
    );

    // handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _client.dio.post(
        '/devices/token',
        data: {'fcm_token': newToken, 'platform': 'ANDROID'},
      );
    });
  }
}
