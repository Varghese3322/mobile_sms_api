import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> saveFcmToken({
  required int userId,
  required String androidId,
  required String fcmToken,
}) async {
  final response = await http.post(
    Uri.parse("http://sms.apihub.co.in/api/save-fcm-token/"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "user_id": userId,
      "android_id": androidId,
      "fcm_token": fcmToken,
      "platform": "android"
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to save FCM token");
  }
}
