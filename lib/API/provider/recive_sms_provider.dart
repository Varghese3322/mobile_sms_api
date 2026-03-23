import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ReceiveSmsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool success = false;
  String? error;

  Future<void> sendIncomingSms({
    required int userId,
    required int deviceId,
    required int sim,
    required String fromNumber,
    required String message,
  }) async {
    isLoading = true;
    success = false;
    error = null;
    notifyListeners();

    final url = Uri.parse("http://sms.apihub.co.in/api/receive-sms/");

    debugPrint("🌐 API URL: $url");

    final payload = {
      "user_id": userId,
      "device_id": deviceId,
      "sim": sim,
      "from_number": fromNumber,
      "message": message,
    };

    debugPrint("📦 PAYLOAD: $payload");

    try {
      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint("📥 STATUS: ${response.statusCode}");
      debugPrint("📥 BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        success = data["success"] == true;

        debugPrint("✅ API SUCCESS");
        debugPrint("🆔 SMS ID: ${data["sms_id"]}");
        debugPrint("📨 MESSAGE: ${data["message"]}");
      } else {
        error = "Server error: ${response.statusCode}";
      }
    } catch (e) {
      error = e.toString();
      debugPrint("❌ EXCEPTION: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}
