import 'package:flutter/services.dart';

class NativeSms {
  static const MethodChannel _channel = MethodChannel("sms_channel");

  /// Send SMS via platform channel, returns true if sent
  static Future<bool> send({
    required String phone,
    required String message,
    required int sim,
  }) async {
    try {
      await _channel.invokeMethod("sendSms", {
        "phone": phone,
        "message": message,
        "simSlot": sim,
      });
      print("✅ SMS SENT: $phone (SIM $sim)");
      return true;
    } catch (e, st) {
      print("❌ SMS SEND FAILED: $e\n$st");
      return false;
    }
  }
}
