import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';



@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  const platform = MethodChannel("native_sms");

  final data = message.data;

  if (data['type'] == "SEND_SMS") {
    await platform.invokeMethod("sendSms", {
      "phone": data['phone'],
      "message": data['message'],
    });
  }
}

