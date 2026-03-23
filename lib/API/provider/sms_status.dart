import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SmsStatusProvider extends ChangeNotifier {
  Future<void> updateSmsStatus({
    required int smsId,
    required String status,
  }) async {
    final url = Uri.parse(
      "http://sms.apihub.co.in/api/update-status/",
    );

    final body = {
      "sms_id": smsId,
      "status": status,
    };

    try {
      debugPrint("🚀 UPDATE STATUS API CALLED");
      debugPrint("📤 BODY: $body");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      debugPrint("📥 STATUS CODE: ${response.statusCode}");
      debugPrint("📥 RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("✅ STATUS UPDATED → ${data['updated_status']}");
      } else {
        debugPrint("❌ STATUS UPDATE FAILED");
      }
    } catch (e) {
      debugPrint("❌ UPDATE STATUS ERROR: $e");
    }
  }
}
